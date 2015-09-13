#!/usr/local/bin/python3 -bb

import argparse
import atexit
import collections
import datetime
import logging
import os
import stat
import subprocess
import sys


Config = collections.namedtuple('Config', ['device', 'key', 'zpool', 'filesystems', 'detach'])

configs = {
  'name': Config(
    device='/dev/da0', key='path-to-key', zpool='zpool-to-backup',
    filesystems=['zpool-to-backup/zfs0', 'zpool-to-backup/zfs1'],
    detach=True),
}


class Exec(object):
  """Wraps a process.

  Args:
    dryrun: (bool) True; echoes the command rather than runs it.
    pipefrom: (Exec) if the input to this exec should be another Exec.

  Properties:
    output: Output from program (string)
    returncode: Return code from program.
  """
  def __init__(self, *args, **kwargs):
    if kwargs.get('dryrun', False):
      args = ['echo'] + list(args)

    pipe = kwargs.get('pipe', False)
    pipefrom = kwargs.get('pipefrom', None)
    stdin = None
    if pipefrom:
      stdin = pipefrom.proc.stdout

    self.args = args
    self.output = ''    # Initialise to a reasonable value.
    self.proc = subprocess.Popen(
      args, stdin=stdin,
      stdout=subprocess.PIPE)

    if pipefrom:
      pipefrom.proc.stdout.close()
      logging.info('%s | %s', ' '.join(pipefrom.proc.args), ' '.join(args))

    # We're piped into something else; let that do the work.
    if pipe:
      return

    out = self.proc.communicate()
    self.output = str(out[0], encoding='utf8').strip()
    self.returncode = self.proc.returncode

    self.Log()

  def Success(self):
    return self.proc.returncode == 0

  def Args(self):
    return ' '.join(self.args)

  def Log(self):
    ret = self.proc.returncode
    args = self.Args()
    if self.Success():
      logging.debug('exec [return=%d]: %s', ret, args)
    else:
      logging.error('fail [return=%d]: %s: %s', ret, args, self.output)


class OffsiteStorage(object):
  def __init__(self, device, key_file, zpool_name,
               pass_file='/dev/null', dryrun=False):
    self._device = device
    self._key_file = key_file
    self._pass_file = pass_file
    self._zpool_name = zpool_name
    self._dryrun = dryrun

    # State
    self._is_attached = False
    self._is_imported = False
    self._is_file_attached = False
    self._filename = None

    self._Init()

  def _Init(self):
    # Figure out if this is a file-backed device.
    st = os.stat(self._device)
    self._is_file_backed = stat.S_ISREG(st.st_mode)

    def Split(exc, delim='\t'):
      return [line.split(delim) for line in exc.output.split('\n')]

    exc = Exec('zpool', 'list', '-H', dryrun=False)
    if exc.Success():
      names = [pool[0] for pool in Split(exc) if pool[-2] == 'ONLINE']
      self._is_imported = self._zpool_name in names
      # Imported implies attached.
      self._is_attached = self._is_imported

    if self._is_file_backed:
      self._filename = self._device

      exc = Exec('mdconfig', '-lv', dryrun=False)
      devs = [dev[0] for dev in Split(exc) if dev[-1] == self._filename]
      if devs:
        self._is_file_attached = True
        self._device = '/dev/' + devs[0]

    if not self._is_attached:
      exc = Exec('geli', 'status', '-s', dryrun=False)
      dev = self._device[5:]    # /dev/foo -> foo
      devs = [dev[-1] for dev in Split(exc, delim='  ')]
      self._is_attached = dev in devs

  def Attach(self):
    if self._is_file_backed and not self._is_file_attached:
      exc = Exec('mdconfig', '-S', '4096', '-f', self._filename, dryrun=self._dryrun)
      if exc.Success():
        dev = exc.output
        logging.info('Attached %s to %s', self._device, dev)
        self._device = '/dev/' + dev
        self._is_file_attached = True
      else:
        return False

    if not self._is_attached:
      self._is_attached = Exec('geli', 'attach', '-k',
                               self._key_file, '-j',
                               self._pass_file, self._device,
                               dryrun=self._dryrun).Success()

    return self._is_attached

  def Detach(self):
    assert self._is_attached

    device_eli = self._device + '.eli'
    self._is_attached = not Exec('geli', 'detach', device_eli, dryrun=self._dryrun).Success()

    if self._device.startswith('/dev/md'):
      dev = self._device[7:]  # /dev/md5 -> 5
      self._is_file_attached = not Exec('mdconfig', '-d', '-u', dev, dryrun=self._dryrun).Success()

  def Import(self):
    assert self._is_attached

    if not self._is_imported:
      self._is_imported = Exec('zpool', 'import', self._zpool_name, dryrun=self._dryrun).Success()
    return self._is_imported

  def Export(self):
    assert self._is_attached
    assert self._is_imported

    self._is_imported = not Exec('zpool', 'export', self._zpool_name, dryrun=self._dryrun).Success()

  def Cleanup(self):
    if self._is_imported:
      self.Export()
    if self._is_attached:
      self.Detach()


class SnapshotManager(object):
  def __init__(self, offsite_zpool, dryrun=False):
    self._offsite_zpool = offsite_zpool
    self._dryrun = dryrun
    self.LoadSnapshots()

  @property
  def snapshots(self):
    return self._snapshots

  def LoadSnapshots(self):
    exc = Exec('zfs', 'list', '-t', 'snapshot')

    snapshots = {}

    if exc.Success():
      lines = exc.output.split('\n')[1:]

      for line in lines:
        (name, _, _, _, _,) = line.split()

        (fs, snapshot) = name.split('@')

        snapshots.setdefault(fs, [])

        # We tag the snapshots with the dest. zpool, this allows us
        # to differentiate between the same ZFS and different dests
        # (e.g; offsite incremental vs. onsite incremental)
        if '-' + self._offsite_zpool in snapshot:
          snapshots[fs].append(snapshot)

      self._snapshots = snapshots

      logging.info('Snapshots loaded: %s', self._snapshots)
    else:
      logging.error('Unable to load snapshots, zfs list = %d', code)
      logging.debug('zfs list returned: %s', out)

  def Snapshot(self, zfs):
    now = datetime.datetime.now()
    name = '%.4d%.2d%.2d%.2d%.2d-%s' % (now.year, now.month, now.day,
                                        now.hour, now.minute, self._offsite_zpool)

    if Exec('zfs', 'snapshot', '%s@%s' % (zfs, name), dryrun=self._dryrun).Success():
      return name
    else:
      return None

  def Destroy(self, fs, snapshot):
    return Exec('zfs', 'destroy', '%s@%s' % (fs, snapshot), dryrun=self._dryrun).Success()

  def Rollback(self, fs, snapshot):
    return Exec('zfs', 'rollback', '%s@%s' % (fs, snapshot), dryrun=self._dryrun).Success()

  def GetDestination(self, fs):
    return '%s/%s' % (self._offsite_zpool, fs.split('/', 1)[1])

  def Transmit(self, fs, snapshot, dest_fs, from_snapshot=None):
    zfs_send_args = ['zfs', 'send']
    if from_snapshot:
      zfs_send_args += ['-i', '%s@%s' % (fs, from_snapshot)]
    zfs_send_args += ['%s@%s' % (fs, snapshot)]

    # Compute destination.
    zfs_recv_args = ['zfs', 'receive']
    if dest_fs in self._snapshots and not from_snapshot:
      logging.info('%s exists, forcing zfs receive', dest_fs)
      zfs_recv_args += ['-F']
    zfs_recv_args += [dest_fs]

    # from_snapshot means send an incremental snap.
    logging.info('Sending %s@%s (base=%s) to %s' % (fs, snapshot,
                                                    from_snapshot,dest_fs))

    zfs_send = Exec(*zfs_send_args, dryrun=self._dryrun, pipe=True)
    zfs_recv = Exec(*zfs_recv_args, dryrun=self._dryrun, pipefrom=zfs_send)

    return zfs_recv.Success()


def main(dryrun, config):
  storage = OffsiteStorage(config.device, config.key, config.zpool, dryrun=dryrun)
  filesystems = config.filesystems

  if storage.Attach() and storage.Import():
    snap_mgr = SnapshotManager(config.zpool, dryrun)
    snapshots = snap_mgr.snapshots

    for fs in filesystems:
      logging.info('Processing %s', fs)

      snaps_for_fs = snapshots.get(fs, [])
      dest_fs = snap_mgr.GetDestination(fs)

      logging.info('Destination %s', dest_fs)

      snaps_for_dest_fs = snapshots.get(dest_fs, [])

      # The both source and dest have the same last common snapshot,
      # use it as the base for an incremental send. Otherwise, we'll
      # send the whole fs.
      from_snap = None
      if snaps_for_dest_fs:
        last_from_offsite = snaps_for_dest_fs[-1]
        if last_from_offsite in snaps_for_fs:
          from_snap = last_from_offsite

      if from_snap:
        logging.info('Using %s as incremental base snapshot',
                     from_snap)

        # Let's rollback to this snapshot so we can do incrementals,
        # in case it's changed in between.
        if not snap_mgr.Rollback(dest_fs, from_snap):
          logging.error('Unable to rollback %s to %s, not using it.',
                        dest_fs, from_snap)
          logging.error('This will probably require manual intervention to '
                        'cleanup all snapshots on %s.', dest_fs)

          from_snap = None
      else:
        logging.info('No common base snapshot.')

      new_snap = snap_mgr.Snapshot(fs)
      if not new_snap:
        logging.error('Unable to take snapshot of %s', fs)
      else:
        if snap_mgr.Transmit(fs, new_snap, dest_fs, from_snap):
          if from_snap:
            snap_mgr.Destroy(fs, from_snap)
            snap_mgr.Destroy(dest_fs, from_snap)
        else:
          logging.error('Unable to backup %s', fs)

  else:
    logging.error('Unable to attach and import storage.')

  if config.detach:
    storage.Cleanup()


def write_lock(config_name):
  lockfile = '/var/run/zfs_incr-' + config_name + '.pid'
  pid = None
  try:
    st = os.stat(lockfile)
    with open(lockfile, 'r') as f:
      pid = f.read().strip()
  except FileNotFoundError:
    pass

  if pid:
    try:
      os.kill(int(pid), 0)
      logging.fatal('Detected running zfs_incr process pid=%s (pidfile=%s), abort', pid, lockfile)
      sys.exit(2)
    except ProcessLookupError:
      pass

  with open(lockfile, 'w') as f:
    f.write(str(os.getpid()))

  return lockfile

if __name__ == '__main__':
  parser = argparse.ArgumentParser(prog=sys.argv[0])
  parser.add_argument('--dryrun', help='Runs in dry-run mode', action='store_true')
  parser.add_argument('--logfile', nargs='?', help='Log to file')
  parser.add_argument('config', nargs='?', help='Configuration name to run')
  parser.set_defaults(dryrun=False)
  args = parser.parse_args()

  if not args.config in configs:
    print('Config %s unknown' % args.config)
    sys.exit(1)

  largs = {
    'format': '%(asctime)s %(levelname)s %(message)s',
    'datefmt': '%Y/%m/%d %H:%M:%S',
    'level': logging.DEBUG
  }
  if args.logfile:
    largs['filename'] = args.logfile
  else:
    largs['stream'] = sys.stdout
  logging.basicConfig(**largs)

  logging.info('Starting up (dryrun=%s)...', args.dryrun)

  lock = write_lock(args.config)
  atexit.register(os.unlink, lock)

  main(args.dryrun, configs[args.config])
  logging.info('Complete.')
