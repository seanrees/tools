# This is a simple helper to make metric name creation easier
# for OpenTSDB.

import logging
import re

# List of words that don't really add any value to metric
# names. We strip these out when we make a metric from some existing
# string. These might be BIND-specific.
BORING_WORDS = [
  'statistics',
  'resulted in',
  'answer'
]

def Sanitize(s):
  """Sanitizes special characters for use in OpenTSDB metric names.

  TODO: decide whether or not this is a good idea.
  """

  s = s.strip()

  # p/i -> p-i; matches tcp/ip (e.g; from BIND).
  s = s.replace('p/i', 'p-i')

  # Replace ! with 'not-'.
  s = s.replace('!', 'not-')

  # Purge all other 'special' characters.
  s = re.sub(r'[^A-Za-z0-9- ]', '', s)

  # Replace ' ' with _
  s = s.replace(' ', '_')

  return s

def MakeMetric(prefix, section, stat=None):
  """Builds a metric name.

  Args:
    prefix: prefix for the metric.
    section: name of section or statistic name.
    stat: individual stat, not required.

  Returns:
    prefix.section or prefix.section.stat depending on if
    stat is supplied.
  """

  def Cleanup(s):
    s = s.lower()
    for word in BORING_WORDS:
      s = s.replace(word, '').replace('  ', ' ')
    return Sanitize(s)

  prefix = Cleanup(prefix)
  section = Cleanup(section)

  # Hack, I trimmed this out in an earlier version and now I'm stuck,
  # so leave this here for now. TODO(fix!)
  section = section.replace('_queries', '')

  metric = '%s.%s' % (prefix, section)

  if stat:
    metric += '.%s' % Cleanup(stat)

  return metric
