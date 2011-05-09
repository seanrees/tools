#!/usr/bin/env python
#
# A bit of code that reads BIND statistics and outputs in an
# OpenTSDB-friendly way.
#
# Sean Rees <sean@rees.us>
# 9/May/2011
#

from lib import bind_stats_parser
from lib import metric_helper
from lib import opentsdb_writer

import logging
import sys

# File to read by default.
DEFAULT_BIND_STATS_FILE = '/var/named/var/stats/named.stats'

def main(argv):
  file = DEFAULT_BIND_STATS_FILE

  if len(argv) > 1:
    file = argv[1]

  parser = bind_stats_parser.BindStatsParser(file)
  stats = parser.Parse()

  tsdb = opentsdb_writer.OpenTSDBWriter()

  for (section, view, subsection, value, stat) in stats:
    metric = metric_helper.MakeMetric('bind', section, stat)

    tsdb.Write(metric, value, view=view, domain=subsection)

  tsdb.Flush(sys.stdout)


if __name__ == '__main__':
  #logging.basicConfig(
  #  level=logging.DEBUG,
  #  format='%(asctime)s %(message)s',
  #  datefmt='%m/%d/%Y %H:%M:%S')

  main(sys.argv)
