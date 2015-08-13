#!/usr/bin/env python

import marshal
import sys
import time

def main(argv):
  output = '/tmp/magnet_state.out'
  tolerance = 20        # seconds.
  key = argv[1]

  with open(output, 'rb') as f:
    data = marshal.load(f)
    now = time.time()
    if data['ts'] + tolerance >= now:
      if key in data:
        print data[key]
      else:
        print >>sys.stderr, 'Unknown key: %s' % key

if __name__ == '__main__':
  main(sys.argv)
