#!/usr/bin/env python3

import argparse
import os
import sys
import subprocess
import time
import signal
import random
import re

class Pgen():
  verbose = 0

  links_high = 0x3c0
  links_low = 0x3f

  pgen_mask_half = links_high | links_low
  pgen_mask = pgen_mask_half << 10 | pgen_mask_half

  directory = os.path.dirname(__file__)

  def __init__(self, id, verbose):
    self.verbose = verbose
    self.id = id
    self.tcru = ['tcru', '--id', self.id]
    self.seed()
    #self.ovrStreamActive()
    self.occupancyDefault()
    self.enable(1)

  def __del__(self):
    self.enable(0)


  def run_cmd(self, cmd):
    if self.verbose > 1:
      print(cmd)
    p = subprocess.run(cmd, capture_output=True)
    # Always print error output
    if p.stderr:
      print(p.stderr.decode('utf-8'))
    if p.stdout and self.verbose > 1:
      print(p.stdout.decode('utf-8'))

  def enable(self, val):
    self.run_cmd(self.tcru + ['--pgen', '{:d}'.format(val)])
  def seed(self):
    self.run_cmd(self.tcru + ['--pgen-seed-default', '-m', '0x{:05x}'.format(self.pgen_mask)])
  def ovrStreamActive(self):
    self.run_cmd(self.tcru + [ '--pgen-ovr-sactive', '0x{:05x}'.format(self.pgen_mask)])
  def occupancyDefault(self):
    self.run_cmd(self.tcru + ['--pgen-occupancy-default', '-m', '0x{:05x}'.format(self.pgen_mask)])
  def occupancy(self, linkmask, occupancy):
    self.run_cmd(self.tcru + ['--pgen-occupancy', '{:d}'.format(occupancy), '-m', '0x{:05x}'.format(linkmask)])


  def getLinkMask(self, iteration = 0):
    m = 0

    if (iteration % 20001) < 27:
      m = self.links_high
    elif (iteration % 23001) < 31:
      m = self.links_low
    elif (iteration % 102123) < 3:
      m = self.pgen_mask_half
    else:
      m = random.randint(0, self.pgen_mask_half)
    return m << 10 | m


def run_test(ids, occ_min = 0, occ_max = 50, verbose = 0):
    random.seed(0xdeadbeef)

    pgens = [Pgen(id, verbose) for id in ids]

    # Always allow links to become empty
    #   Doesn't matter if 0 is in the list twice, will just slightly increase the chance for empty links
    allowedOccupancies = [0] + list(range(occ_min, occ_max+1))
    print('Allowed link occupancies: ' + str(allowedOccupancies))

    i = 0

    try:
      print('Starting test on CRUs {:s}'.format(str(ids)))

      while True:
        for p in pgens:
          o = random.choice(allowedOccupancies)
          l = p.getLinkMask(i)

          if verbose > 0:
             print('CRU {:s}: Setting occupancy {:2d}% for links 0x{:05x}'.format(p.id, o, l))

          p.occupancy(l, o)

        time.sleep(.25)
        i += 1
    except KeyboardInterrupt:
      print('Received keyboard interrupt in interation {:d}, finalizing test now'.format(i))
      return
    except Exception as e:
      print(e)
      print('Received exception in iteration {:d}, finalizing test now'.format(i))
      return


def get_cru_serialnumbers(args):
  serials = []

  p = subprocess.run(['/opt/o2/bin/roc-list-cards'], capture_output=True)
  output = p.stdout.decode('utf-8')

  for i, l in enumerate(output.splitlines()):
    ms = '\s+(?P<n>[0-9])\s+CRU\s+(?P<bdf>[0-9a-fA-F\:\.]+)\s+(?P<serial>[0-9]+)'
    ma = re.match(ms, l)
    if ma:
      print(l)

      if ma['serial'] not in serials:
        serials.append(ma['serial'])

  if args.verbose > 0:
    print('Detected CRU serials: {:s}'.format(str(serials)))

  return serials


def handler(signum, frame):
  signame = signal.Signals(signum).name
  raise RuntimeError('Signal handler called with signal {:s} ({:d})'.format(signame, signum))


def main():
  desc_text =  'Control script for TPC CRU UL pattern generators'
  epilog_text = 'Additional information:\n'\
                '  Usage: pgen-control.py --verbose 1 --occupancy-max 10\n'\
                '         pgen-control.py --id 04:00.0\n'\
                '         pgen-control.py --id 0210 --verbose 1 --occupancy-min 10 --occupancy-max 10\n'\
                '\n'\
                '  When using clush to run this script on multiple FLPs, make sure to add \'ssh_options: -tt\' to clush.conf\n'\
                '  to allow signal forwarding with ssh. Also make sure key passphrase is added to ssh-agent and FLPs are\n'\
                '  configured in ssh config\n'\
                '  Usage example with clush:\n'\
                '    clush -b -L -v -w flp[073-074] \'<path>/pgen-control.py --debug 2 --verbose 1 --occupancy-max 15\''
#

	# Command line parsing
  parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter, description=desc_text, epilog=epilog_text)
  parser.add_argument('--debug', type=int, nargs='?')
  parser.add_argument('--verbose', type=int, default=0, help='Increase verbosity')
  parser.add_argument('--id', type=str, default='auto', help='Specify CRU IDs to run command on. If set to auto, detect available CRUs and run on all')
  parser.add_argument('--occupancy-min', type=int, default=0, help='Set minimum (avg.) link occupancy')
  parser.add_argument('--occupancy-max', type=int, default=20, help='Set maximum (avg.) link occupancy')
  parser.add_argument('--test', action='store_true')

  args = parser.parse_args()
  if 'debug' in args and args.debug:
    print(args)

  if 'test' in args and args.test:
    print('No test defined')
    sys.exit(0)

  signal.signal(signal.SIGALRM, handler)
  signal.signal(signal.SIGTERM, handler)
  signal.signal(signal.SIGPIPE, handler)
  signal.signal(signal.SIGHUP, handler)
  signal.signal(signal.SIGABRT, handler)
  signal.signal(signal.SIGUSR1, handler)
  signal.signal(signal.SIGUSR2, handler)

  ids = []
  if args.id == 'auto':
    ids = get_cru_serialnumbers(args)
  else:
    ids.append(args.id)

  run_test(ids, verbose = args.verbose, occ_min = args.occupancy_min, occ_max = args.occupancy_max)

if __name__ == "__main__":
  main()
