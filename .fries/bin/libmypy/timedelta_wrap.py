# Last Modified: 2016.02.08 /coding: utf-8
# Copyright: © 2015-2016 Landon Bouma.
# License: GPLv3. See LICENSE.txt.

import os
import sys

from datetime import timedelta
import time

import logging
log = logging.getLogger('timedelta_wrap')

from inflector import Inflector

class timedelta_wrap(timedelta):

  # Contains fcns. cxpx'ed from Cyclopath's pyserver/util_/misc.py

  # CAVEAT: Unlike datetime.timedelta, which accepts weeks but not
  # months or years because not every month nor every year has the
  # same number of days, this script fudges tbe calculation so we
  # can pretty-print an approximate elapsed time.

  # https://en.wikipedia.org/wiki/Tropical_year
  #  Laskar's expression: Mean tropical year on 1/1/2000 was 365.242189 days.
  #  Gregorian calendar average year is 365.2425 days, matching northward
  #  (March) equinox year of 365.2424 days (as of January 2000).
  # Calculating from rough estimate of 365d 5h 48m 46s per year.
  #  time_in_year = timedelta(days=365, hours=5, minutes=48, seconds=46)
  #  secs_in_year = time_in_year.total_seconds() # 31556926
  #  days_in_year = secs_in_year / 24.0 / 60.0 / 60.0 # 365.2421991
  # Calculating from scholarly numbers.
  days_in_year = 365.242189 # Laskar's expression.
  secs_in_day = 86400 # 1/86,400 is mean of solar day.
  secs_in_year = days_in_year * secs_in_day # 31556925.1296

  # Average number of days in a month.
  # MAGIC_NUMBERS: 7 months are 31 days long, 4 are 40, and one is 28ish.
  #  avg_month_days = (7*31 + 4*30 + 28.25) / 12.0 # 30.4375
  days_in_month = days_in_year / 12.0 # 30.436849
  secs_in_month = secs_in_year / 12.0 # 2629743.7608

  def __new__(
    cls,
    days=0,
    seconds=0,
    microseconds=0,
    milliseconds=0,
    minutes=0,
    hours=0,
    weeks=0,
    fortnights=0,
    months=0,
    seasons=0,
    years=0,
    bienniums=0,
    decades=0,
    jubilees=0,
    centuries=0,
    millenniums=0,
    ages=0,
    megaannums=0,
    epochs=0,
    eras=0,
    eons=0,
    gigaannums=0,
  ):

    # Ref: https://en.wikipedia.org/wiki/Unit_of_time
    # FIXME: 2015.02.04: Needs testing, especially because overflows
    #        might mean parent class can only represent so many days.
    n_years = 0
    n_years +=   1000000000 * gigaannums
    n_years +=    500000000 * eons
    n_years +=    100000000 * eras
    n_years +=     10000000 * epochs
    n_years +=      1000000 * megaannums
    n_years +=      1000000 * ages
    n_years +=         1000 * millenniums
    n_years +=          100 * centuries
    n_years +=           50 * jubilees
    n_years +=           10 * decades
    n_years +=            2 * bienniums
    n_years +=            1 * years
    n_years +=         0.25 * seasons
    n_days = n_years * timedelta_wrap.days_in_year
    n_days += timedelta_wrap.days_in_month * months
    n_days +=            14 * fortnights
    days += n_days

    # Watch out for OverflowError.
    #   >>> timedelta(math.pow(2,31))
    #   OverflowError: normalized days too large to fit in a C int
    # Also note different (but similar) errors, one being more helpful.
    #   >>> timedelta(math.pow(2,30))
    #   OverflowError: days=1073741824; must have magnitude <= 999999999
    # Checking the more better error message:
    #   >>> timedelta(999999999)
    #   datetime.timedelta(999999999)
    #   >>> timedelta(1000000000)
    #   OverflowError: days=1000000000; must have magnitude <= 999999999
    #
    # BUG nnnn/WONTFIX: Support any int and not just C ints.
    #                   999999999/365.242189 = 2737909.3
    #                   so we can only support megaannums and nothing more.
    #                   (At least total_seconds() works 'til infinity!)
    if days > 999999999:
      log.error('BUG nnnn: That many days is not supported. Try <= 999999999')

    self = timedelta.__new__(
      cls,
      days=days,
      seconds=0,
      microseconds=0,
      milliseconds=0,
      minutes=0,
      hours=0,
      weeks=0,
    )
    return self

  @staticmethod
  def time_format_elapsed(time_then, time_now=None):
    if time_now is None:
      time_now = time.time()
    secs_elapsed = time_now - time_then
    tdw = timedelta_wrap(seconds=secs_elapsed)
    return tdw.time_format_scaled()[0]

  def time_format_scaled(self):

    # FIXME: Move this fcn. into its own class like datetime.timedelta?
    #        Or extend datetime.timedelta?
    #        Note that timedelta converts the difference between two
    #        dates or times into number of days, seconds, and microseconds.
    #        We could extend timedelta and rename this fcn, e.g.,
    #         pretty_print(), or something...

    add_period = ''
    if self.total_seconds() > timedelta_wrap.secs_in_year:
      tm_unit = 'year'
      s_scale = timedelta_wrap.secs_in_year
    elif self.total_seconds() > timedelta_wrap.secs_in_month:
      tm_unit = 'month'
      s_scale = timedelta_wrap.secs_in_month
    elif self.total_seconds() > timedelta_wrap.secs_in_day:
      tm_unit = 'day'
      s_scale = timedelta_wrap.secs_in_day
    elif self.total_seconds() > (60 * 60): # secs/min * mins/hour = secs/hour
      tm_unit = 'hour'
      s_scale = 60.0 * 60.0 # secs_in_hour
    elif self.total_seconds() > 60: # secs/min = secs/min
      tm_unit = 'min'
      s_scale = 60.0 # secs_in_minute
      add_period = '.'
    else:
      tm_unit = 'sec'
      s_scale = 1.0 # secs_in_second
      add_period = '.'

    adj_time = self.total_seconds() / s_scale
    time_fmtd = ('%.2f %s' % (
      adj_time, Inflector.pluralize(tm_unit, adj_time != 1),
    ))
    time_fmtd += add_period

    return time_fmtd, s_scale, tm_unit

# end: timedelta_wrap

if (__name__ == '__main__'):
   pass

