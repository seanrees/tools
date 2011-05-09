# Parses out BIND stats.

import logging

class BindStatsParser(object):

  def __init__(self, filename, read_back_bytes=2048):
    """Parses BIND stats from a BIND (9.6+) stats file.

    This code is optimized to read from the rear of the file. It starts
    at the end and reads in read_back_bytes chunks for the starting stanza
    of a stats dump. It then concatenates those chunks in memory and parses.

    If you have tons of domains, setting a higher value for read_back_bytes
    is an avenue for optimization. For most users, 2K should be sufficient.

    Args:
      filename: (string) name of file to read.
      read_back_bytes: (int) how large of chunks to read back.
    """
    self._filename = filename
    self._read_back_bytes = read_back_bytes

    self._logger = logging.getLogger(self.__class__.__name__)

  def GetLatestStats(self):
    """Reads back on the file and returns the latest statistics dump text."""

    chunks = []

    with open(self._filename, 'r') as f:
      found = False

      self._logger.info('Starting to read %s', self._filename)

      # Seek to the end.
      f.seek(0, 2)

      while not found:
        next_chunk_start = f.tell() - self._read_back_bytes

        if next_chunk_start < 0:
          next_chunk_start = 0

        f.seek(next_chunk_start)
        chunk = f.read(self._read_back_bytes)

        start_pos = chunk.lstrip().rfind('+++ Statistics Dump +++')

        if start_pos >= 0:
          self._logger.debug('Found starting stanza at byte %d',
                             next_chunk_start + start_pos)

          chunks.append(chunk.lstrip()[start_pos:])
          found = True
        else:
          # Haven't found the start stanza, keep looking.
          chunks.append(chunk)

          # Back up to where we started.
          f.seek(next_chunk_start)

    self._logger.info('Read %d (%dK) chunks from %s',
                      len(chunks), self._read_back_bytes/1024, self._filename)

    # Put the chunks back in proper front-to-back order.
    chunks.reverse()

    return ''.join(chunks).strip()


  def Parse(self, lines=None):
    """Parses a statistics dump and returns a list of tuples for the results.

    Args:
      lines: lines (unsplit) from GetLatestStats(). If None, calls
             GetLatestStats().

    Returns:
      list of tuples (section, view, subsection, count, stat).
    """

    if not lines:
      lines = self.GetLatestStats()

    lines = lines.split('\n')

    current_section = None
    current_view = None
    current_subsection = None

    stats = []

    for line in lines:
      if line.startswith('++'):
        current_section = line[3:-3]    # Strip plusses.
        current_view = None             # New section resets view and
        current_subsection = None       # subsection.
      elif line.startswith('[View:'):
        current_view = line[7:-1]       # Strip [View:...].
      elif line.startswith('['):
        current_subsection = line[1:-1] # Strip brackets.

        if current_subsection.find(" ") > 0:
          current_subsection, view = current_subsection.split(" ", 1)
          current_view = view.split(" ")[1][:-1]
      elif line.startswith('---'):
        # Ignore. This should mean we're finished.
        continue
      else:
        count, stat = line.strip().split(' ', 1)

        stats.append(
          (current_section, current_view, current_subsection, count, stat))

    return stats
