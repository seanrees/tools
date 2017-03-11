#!/usr/bin/python3
#
# TODO: make this use the prometheus API. hanging this off node exporter
# is dumb (but easy).
#

import argparse
import collections
import io
import subprocess
import sys

def get_boinc_state(boinccmd):
  args = [boinccmd, '--get_state']
  proc = subprocess.run(args, stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT, check=True)

  return proc.stdout

# Not the most efficient, but saves me some effort.
def section(lines, section):
  started = False
  for l in lines:
    if l.startswith("===="):
      # We've reached the start of the *next* section, so we're done.
      if started:
        break

      # This is the section we want. Skip yielding this
      # line since it's just a header.
      if section in l:
        started = True
        continue

    if started:
      yield l.strip()

def parse(section, headings):
  out = []
  for l in section:
    if l.endswith('----'):
      out.append({})

    if not l:
      break

    if out and ': ' in l:
      k, v = l.split(': ')
      if k in headings and k not in out[-1]:
        out[-1][k] = v

  return out

def print_projects(projects):
  # These are all counters.
  for p in projects:
    name = p['name']
    del(p['name'])
    for k, v in p.items():
      var = 'boinc_project_%s' % k
      print('# TYPE %s counter' % var)
      print('%s{name="%s"} %s' % (var, name, v))

def print_tasks(tasks):
  states = collections.defaultdict(int)

  # Tasks oscillate between these two states; so preset
  # them to zero.
  states['SUSPENDED'] = 0
  states['EXECUTING'] = 0

  print('# TYPE boinc_task_fraction_done gauge')
  print('# TYPE boinc_task_current_cpu_time counter')
  for t in tasks:
    name = t['name']
    state = t['active_task_state']
    done = float(t['fraction done'])*100
    cpu = t['current CPU time']

    states[state] += 1
    print('boinc_task_fraction_done{name="%s"} %s' % (name, done))
    print('boinc_task_current_cpu_time{name="%s"} %s' % (name, cpu))

  print('# TYPE boinc_task_state gauge')
  for state, count in states.items():
    print('boinc_task_state{state="%s"} %s' % (state, count))

def main(boinccmd):
  state = get_boinc_state(boinccmd)
  lines = io.TextIOWrapper(io.BytesIO(state)).readlines()

  projects = []
  headings = ['name', 'user_total_credit', 'user_expavg_credit',
              'host_total_credit', 'host_expavg_credit']
  projects = parse(section(lines, 'Projects'), headings)
  print_projects(projects)

  headings = ['name', 'active_task_state', 'fraction done', 'current CPU time']
  tasks = parse(section(lines, 'Tasks'), headings)
  print_tasks(tasks)


if __name__ == '__main__':
  parser = argparse.ArgumentParser(prog=sys.argv[0])
  parser.add_argument(
          '--boinccmd', metavar='B',
          default='/usr/bin/boinccmd',
          help='Path to boinccmd')

  args = parser.parse_args()
  main(boinccmd=args.boinccmd)
