# Simple module to output TSDB statistics.

import logging
import socket
import sys
import time

class OpenTSDBWriter:
  def __init__(self, timestamp=None, hostname=None):
    self._timestamp = (int)(time.time())
    self._hostname = socket.gethostname()

    self._logger = logging.getLogger(self.__class__.__name__)

    self._lines = []

    self._logger.info('Created OpenTSDB writer for ts=%d host=%s',
                      self._timestamp, self._hostname)

  def Write(self, metric, value, **kwargs):
    tsdb = ('put %s %u %s host=%s' %
            (metric, self._timestamp, value, self._hostname))

    for k in kwargs:
      v = kwargs[k]
      if v:
        tsdb += ' %s=%s' % (k,v)

    self._logger.debug('[TSDB] %s', tsdb)

    self._lines.append(tsdb)

  def Flush(self, stream=sys.stdout):
    self._logger.debug('Flushing to %s', stream)

    for line in self._lines:
      stream.write(line + '\n')
