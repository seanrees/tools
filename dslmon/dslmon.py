#!/usr/bin/env python

from stats_parser import StatsParser
from dashboard_builder import DashboardBuilder
import os

FILE='/tmp/zyxel-data.txt'

stat = None
try:
    stat = os.stat(FILE)
except:
    sys.exit(1)

file = file(FILE)
data = file.read()

stats = StatsParser().parse(data)
stats['time'] = stat.st_mtime #override

print "Content-Type: text/html\r\n"
print DashboardBuilder(stats).build()
