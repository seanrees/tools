#!/usr/bin/env python
#
# lapse.py fetches /jpeg from a given IP address once per second
# and writes out a file of the form: month/day/hour/minute/second.jpg
#
# You can pass it SIGINFO (^T) to get some runtime statistics.
#
# Usage: lapse.py ipaddress
#

import datetime
import httplib
import logging
import os
import signal
import sys
import time

def fetch_one(camera):
  conn = httplib.HTTPConnection(camera)
  conn.request('GET', '/jpeg')

  jpeg = conn.getresponse().read()

  return jpeg

def write_file(now, jpeg_data):
  month = now.strftime('%m')
  day = now.strftime('%d')
  hour = now.strftime('%H')
  minute = now.strftime('%M')
  second = now.strftime('%S')

  filename = os.path.join(month, day, hour, minute, second + '.jpg')
  dirname = os.path.dirname(filename)

  if not os.path.isdir(dirname):
    os.makedirs(dirname)

  with open(filename, 'w') as f:
    f.write(jpeg_data)

  return f.closed

def main(argv):
  assert len(argv) == 2, "must supply camera ip address as argv[1]"

  camera = argv[1]
  count = 0
  work_time_total = 0
  sleep_time_total = 0
  exceptions = 0

  def siginfo_handler(signum, frame):
    msg = ('Fetched %d images (avg work=%.2f secs), sleep_time=%.2f secs, '
           'exceptions=%d' % (
           count, work_time_total / count, sleep_time_total, exceptions))
    print msg

  signal.signal(signal.SIGINFO, siginfo_handler)

  while True:
    now = datetime.datetime.now()

    try:
      jpeg = fetch_one(camera)
      write_file(now, jpeg)
      count += 1
    except:
      exceptions += 1
      logging.exception('Unexpected exception')

    finished = datetime.datetime.now()
    work_time = finished - now

    work_time_secs = work_time.total_seconds()
    sleep_time_secs = 1 - work_time_secs

    work_time_total += work_time_secs

    # Slow op.
    if work_time_secs > 0.5:
      logging.info('Last operation took %4f seconds, sleeping for %4f',
                   work_time_secs, sleep_time_secs)

    if sleep_time_secs > 0:
      time.sleep(sleep_time_secs)
      sleep_time_total += sleep_time_secs

if __name__ == '__main__':
  logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s',
                      datefmt='%Y/%m/%d %H:%M:%S',
                      filename='cats.log',
                      level=logging.DEBUG)

  logging.info('Started, calling main()')
  main(sys.argv)
  logging.shutdown()
