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

def parse_baseinfo(xdslinfo):
  lines = xdslinfo.split('\r\n')
  data = {}

  for l in lines:
    words = l.split()

    if 'Number of reset' in l:
      data['resets'] = words[-1]

    if 'Payload rate' in l:
      data['upstream_rate'] = words[-1]
      data['downstream_rate'] = words[-2]

    if 'Attenuation' in l:
      data['upstream_attenuation'] = words[-1]
      data['downstream_attenuation'] = words[-2]

    if 'Margins' in l:
      data['upstream_snr'] = words[-1]
      data['downstream_snr'] = words[-2]

    if 'Output power' in l:
      data['upstream_power'] = words[-1]
      data['downstream_power'] = words[-2]

    if 'Loss of signal' in l:
      data['loss_of_signal'] = words[-1]

    if 'Loss of frame' in l:
      data['loss_of_frame'] = words[-1]

    if 'Loss of power' in l:
      data['loss_of_power'] = words[-1]

    if 'Error second' in l:
      data['error_seconds'] = words[-1]

    if 'Code Violation' in l:
      data['code_violation_far'] = words[-1]
      data['code_violation_near'] = words[-2]

    if 'FEC' in l:
      data['fec_far'] = words[-1]
      data['fec_near'] = words[-2]

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
        if near < max_val:
          data[k.lower() + '_near'] = near

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

      logging.info('data = %s', data)

      with open(output, 'wb') as f:
        data['ts'] = int(time.time())
        marshal.dump(data, f)

    except socket.error, se:
      logging.error('Skipping collection, no connection: %s', se)
      telnet = None
    except ValueError, ve:
      logging.error('Dumping to the %s failed: %s', output, ve)

    time.sleep(delay)

if __name__ == '__main__':
  logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s',
                      datefmt='%Y/%m/%d %H:%M:%S',
                      stream=sys.stdout,
                      level=logging.DEBUG)

  logging.info('Starting up...')
  main(sys.argv)
  logging.info('Complete.')
