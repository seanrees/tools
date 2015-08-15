#!/usr/bin/env python

import logging
import marshal
import socket
import sys
import telnetlib
import time

HOST='192.168.1.254'
USERNAME='admin'
PASSWORD='m4gn3tTG589'

def login(host, user, password):
  telnet = telnetlib.Telnet(host)
  telnet.read_until('Username :', 1)
  telnet.write(user + '\r\n')
  telnet.read_until('Password :', 1)
  telnet.write(password + '\r\n')
  telnet.read_until('=>', 1)
  return telnet

def command(telnet, command):
  telnet.write(':' + command + '\r\n')
  output = telnet.read_until('=>')

  # Strip the top and bottom line off.
  return '\r\n'.join(output.split('\r\n'))[1:-1]

def make_key(words):
  # Loss of signal -> loss_of_signal
  return '_'.join(words.lower().split())

def parse_baseinfo(xdslinfo):
  lines = xdslinfo.split('\r\n')
  data = {}

  # Some constants/placeholders.
  FarNearVals = object()
  UpstreamDownstreamVals = object()
  SingleVal = object()
  AutogenKey = object()

  keys = {
    'Loss of signal':  (AutogenKey, SingleVal),
    'Loss of frame':   (AutogenKey, SingleVal),
    'Loss of power':   (AutogenKey, SingleVal),
    'Error second':    ('error_seconds', SingleVal),
    'Number of reset': ('resets', SingleVal),
    'Payload rate':    ('rate', UpstreamDownstreamVals),
    'Attenuation':     (AutogenKey, UpstreamDownstreamVals),
    'Margins':         ('snr', UpstreamDownstreamVals),
    'Output power':    ('power', UpstreamDownstreamVals),
    'Code Violation':  (AutogenKey, FarNearVals),
    'FEC':             (AutogenKey, FarNearVals),
  }

  for l in lines:
    for k, props in keys.iteritems():
      if k in l:
        words = l.split()
        if props[0] == AutogenKey:
          data_key = make_key(k)
        else:
          data_key = props[0]

        if props[1] == SingleVal:
          data[data_key] = words[-1]

        if props[1] == FarNearVals:
          data[data_key + '_far'] = words[-1]
          data[data_key + '_near'] = words[-2]

        if props[1] == UpstreamDownstreamVals:
          data['upstream_' + data_key] = words[-1]
          data['downstream_' + data_key] = words[-2]

        # We found a key, no need to keep searching.
        break

    if 'last 15 minutes' in l:
      break

  return data

def parse_ginp(ginp):
  lines = ginp.split('\r\n')
  data = {}

  keys = ['rtx_tx', 'rtx_c', 'rtx_uc', 'LEFTRS', 'minEFTR', 'errFreeBits']

  for l in lines:
    for k in keys:
      if k in l:
        words = l.split()
        far = int(words[-1])
        near = int(words[-2])
        max_val = pow(2, 31)    # Reports 2^31 for "omg."
        if far < max_val:
          data[k.lower() + '_far'] = far
        else:
          logging.info('Dropping out-of-range %s (far): %d', k, far)

        if near < max_val:
          data[k.lower() + '_near'] = near
        else:
          logging.info('Dropping out-of-range %s (near): %d', k, near)

  return data

def main(args):
  delay = 30
  output = '/tmp/magnet_state.out'
  telnet = None

  while True:
    try:
      if not telnet:
        telnet = login(HOST, USERNAME, PASSWORD)

      xdslinfo = command(telnet, 'xdsl info expand=yes')
      data = parse_baseinfo(xdslinfo)

      ginp = command(telnet, 'xdsl info ginp=yes')
      data.update(parse_ginp(ginp))

      logging.info(data)

      with open(output, 'wb') as f:
        data['ts'] = int(time.time())
        marshal.dump(data, f)

    except socket.error, se:
      logging.error('Skipping collection, no connection: %s', se)
      telnet = None
    except ValueError, ve:
      logging.exception('Dumping to the %s failed: %s', output, ve)

    time.sleep(delay)

if __name__ == '__main__':
  logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s',
                      datefmt='%Y/%m/%d %H:%M:%S',
                      stream=sys.stdout,
                      level=logging.DEBUG)

  logging.info('Starting up...')
  main(sys.argv)
  logging.info('Complete.')
