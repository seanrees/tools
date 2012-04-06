#!/usr/bin/env python

import datetime
import logging
import subprocess
import sys

def Call(*args):
  proc = subprocess.Popen(args,
                          stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT)

  output = proc.communicate()

  logging.debug('exec [return=%d]: %s', proc.returncode, ' '.join(args))

  return (proc.returncode, output[0])


def CallAndLogError(*args):
  (code, out) = Call(*args)

  if code != 0:
    logging.error('exec failed: %s', out)

  return code == 0


class OffsiteStorage(object):
  def __init__(self, device, key_file, pass_file='/dev/null',
               zpool_name='offsite'):
    self._device = device
    self._key_file = key_file
    self._pass_file = pass_file
    self._zpool_name = zpool_name

    # State
    self._is_attached = False
    self._is_imported = False

  def Attach(self):
    self._is_attached = CallAndLogError('geli', 'attach', '-k',
                                        self._key_file, '-j',
                                        self._pass_file, self._device)
    return self._is_attached

  def Detach(self):
    assert self._is_attached

    device_eli = self._device + '.eli'
    self._is_attached = not CallAndLogError('geli', 'detach', device_eli)


  def Import(self):
    assert self._is_attached
    assert not self._is_imported

    self._is_imported = CallAndLogError('zpool', 'import', self._zpool_name)
    return self._is_imported

  def Export(self):
    assert self._is_attached
    assert self._is_imported

    self._is_imported = not CallAndLogError('zpool', 'export',
                                            self._zpool_name)

  def Cleanup(self):
    if self._is_imported:
      self.Export()
    if self._is_attached:
      self.Detach()


class SnapshotManager(object):
  def __init__(self, offsite_zpool='offsite'):
    self._offsite_zpool = offsite_zpool
    self.LoadSnapshots()

  @property
  def snapshots(self):
    return self._snapshots

  def LoadSnapshots(self):
    (code, out) = Call('zfs', 'list', '-t', 'snapshot')

    snapshots = {}

    if code == 0:
      lines = out.split('\n')[1:-1]

      for line in lines:
        (name, _, _, _, _,) = line.split()

        (fs, snapshot) = name.split('@')

        snapshots.setdefault(fs, [])

        # We use 'backup' as a keyword here.
        if 'backup' in snapshot:
          snapshots[fs].append(snapshot)

      self._snapshots = snapshots

      logging.info('Snapshots loaded: %s', self._snapshots)
    else:
      logging.error('Unable to load snapshots, zfs list = %d', code)
      logging.debug('zfs list returned: %s', out)

  def Snapshot(self, zfs):
    now = datetime.datetime.now()
    name = '%.4d%.2d%.2d%.2d%.2d-backup' % (now.year, now.month, now.day,
                                            now.hour, now.minute)

    if CallAndLogError('zfs', 'snapshot', '%s@%s' % (zfs, name)):
      return name
    else:
      return False

  def Destroy(self, fs, snapshot):
    return CallAndLogError('zfs', 'destroy', '%s@%s' % (fs, snapshot))

  def Rollback(self, fs, snapshot):
    return CallAndLogError('zfs', 'rollback', '%s@%s' % (fs, snapshot))

  def GetDestination(self, fs):
    return '%s/%s' % (self._offsite_zpool, fs.split('/', 1)[1])

  def Transmit(self, fs, snapshot, dest_fs, from_snapshot=None):
    zfs_send_args = ['zfs', 'send']
    if from_snapshot:
      zfs_send_args += ['-i', '%s@%s' % (fs, from_snapshot)]
    zfs_send_args += ['%s@%s' % (fs, snapshot)]

    logging.debug('exec: %s', ' '.join(zfs_send_args))

    # Compute destination.
    zfs_recv_args = ['zfs', 'receive']
    if dest_fs in self._snapshots and not from_snapshot:
      logging.info('%s exists, forcing zfs receive', dest_fs)
      zfs_recv_args += ['-F']
    zfs_recv_args += [dest_fs]

    logging.debug('pipe-to: %s', ' '.join(zfs_recv_args))

    # from_snapshot means send an incremental snap.
    zfs_send = subprocess.Popen(zfs_send_args,
                                stdout=subprocess.PIPE)
    zfs_recv = subprocess.Popen(zfs_recv_args,
                                stdin=zfs_send.stdout,
                                stdout=subprocess.PIPE)

    zfs_send.stdout.close()

    logging.info('Sending %s@%s (base=%s) to %s' % (fs, snapshot,
                                                    from_snapshot,dest_fs))

    output = zfs_recv.communicate()

    logging.debug('zfs receive returncode = %d', zfs_recv.returncode)

    if zfs_recv.returncode != 0:
      logging.error('ZFS transmit failed: %s', output[0])
      return False

    return True

def main(argv):
  storage = OffsiteStorage('/dev/da0', '/root/offsite.key')
  filesystems = [
    'tank/archive',
    'tank/archive/tm',
    'tank/home',
    'tank/media',
  ]

  if storage.Attach() and storage.Import():
    snap_mgr = SnapshotManager()
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

  storage.Cleanup()


if __name__ == '__main__':
  logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s',
                      datefmt='%Y/%m/%d %H:%M:%S',
                      stream=sys.stdout,
                      level=logging.DEBUG)

  logging.info('Starting up...')
  main(sys.argv)
  logging.info('Complete.')
