# Last Modified: 2016.02.07 /coding: utf-8
# Copyright: © 2011, 2015-2016 Landon Bouma.
# License: GPLv3. See LICENSE.txt.

import os
import sys

# argparse succeeds optparse and requires Python >= 2.7.
# If you need argparse for Py < 2.7, copy the one from
#  /usr/lib/python2.7/argparse.py.
import argparse
import time

from timedelta_wrap import timedelta_wrap

import logging
log = logging.getLogger('argparse_wrap')

__all__ = ['ArgumentParser_Wrap',
           'Simple_Script_Base',]

# Usage: Derive a class from this class and override
#        the two functions, prepare() and verify().

class ArgumentParser_Wrap(argparse.ArgumentParser):

  __slots__ = (
    'script_name',
    'script_version',
    'cli_opts',
    'handled',
    )

  #
  def __init__(self,
      description='',
      script_name=None,
      script_version=None,
      usage=None
  ):
    argparse.ArgumentParser.__init__(self, description, usage)
    if script_name is not None:
      self.script_name = script_name
    else:
      self.script_name = os.path.basename(sys.argv[0])
    if script_version is not None:
      self.script_version = script_version
    else:
      self.script_version = 'X'
    self.cli_opts = None
    self.handled = False

  #
  def get_opts(self):
    self.prepare();
    self.parse();
    self.verify_();
    assert(self.cli_opts is not None)
    return self.cli_opts

  #
  def prepare(self):
    '''
    Defines default CLI options for this script.

    Currently there's just one shared option: -v/-version.

    Derived classes should override this function
    to define more arguments.
    '''
    # Script version.
    self.add_argument(
      '-v', '--version',
      action='version',
      version=('%s version %2s' % (self.script_name,
                                   self.script_version,)))

  #
  def parse(self):
    '''Parse the command line arguments.'''
    self.cli_opts = self.parse_args()

  # *** Helpers: Verify the arguments.

  #
  def verify_(self):
    verified = self.verify()
    # Mark handled if we handled an error, else just return.
    if not verified:
      log.info('Type "%s help" for usage.' % (sys.argv[0],))
      self.handled = True
    return verified

  #
  def verify(self):
    # Placeholder; derived classes may override.
    ok = True
    return ok

   # ***

# ***

class Simple_Script_Base(object):

  __slots__ = (
    'argparser',
    'cli_args',
    'cli_opts',
    'exit_value',
    )

  #
  def __init__(self, argparser):
    self.argparser = argparser
    self.cli_args = None
    self.cli_opts = None
    # If we run as a script, by default we'll return a happy exit code.
    self.exit_value = 0

  #
  def go(self):
    '''
    Parse the command line arguments. If the command line parser didn't
    handle a --help or --version command, call the command processor.
    '''

    time_0 = time.time()

    # Read the CLI args
    self.cli_args = self.argparser()
    self.cli_opts = self.cli_args.get_opts()

    if not self.cli_args.handled:

      log.info('Welcome to the %s!'
               % (self.cli_args.script_name,))

      # Call the derived class's go function.
      self.go_main()

    log.info('Script completed in %s'
             % (timedelta_wrap.time_format_elapsed(time_0),))

    # If we run as a script, be sure to return an exit code.
    return self.exit_value

  #
  def go_main(self):
    pass # Abstract.

  # ***

# ***

if (__name__ == '__main__'):
   pass

