#!/usr/bin/env python3.5
# Last Modified: 2016.02.08 /coding: utf-8
# Copyright: © 2016 Landon Bouma.
#  vim:tw=0:ts=4:sw=4:noet

# LATER/#XXX: day-starts feature.
# LATER/#XXX: Check for gaps feature.
# LATER/#XXX: Double-check time math is inclusive and doesn't round down on minutes...
#             though this might make a day's activities greater than exactly 24 hours?
# LATER/#XXX: Option to print comments/description when itemizing.
#             - Which means using list-all with a search query and maybe dates...
# LATER/#XXX: --only-date or something to specify a 24 hour period?

# FIXME/MAYBE/TRACK: 2016.01.28: [lb] sees the same entry twice -- I corrected
# and entry but there's the old row and the new row, both with the same
# start time... so maybe order by reverse start_time and keep the latest one?
#
# Note the sqlite3's group by selects an arbitrary row and we want the most
# recent row, so we gotta figure out the max id first.
#   select max_id from (
#     select max(id) as max_id from facts
#     where start_time > datetime('2016-01-26')
#       and end_time < datetime('2016-01-27')
#     group by start_time
#   ) as max
#   join facts on (max.max_id = facts.id)
#   order by start_time desc
#
# select * from (  select max(id) as max_id from facts  where start_time > datetime('2016-01-26')    and end_time < datetime('2016-01-27')  group by start_time) as max join facts on (max.max_id = facts.id) order by start_time desc;

import os
import sys

import datetime
import re
import sqlite3
import subprocess
import time

# MAYBE: Install pyoilerplate to site-packages and treat as 3d party lib.
sys.path.append('%s/libmypy' % (os.path.abspath(sys.path[0]),))
from libmypy import argparse_wrap

import logging
from libmypy import logging2
logging2.init_logging(logging.DEBUG, log_to_console=True)
log = logging.getLogger('argparse_wrap')

SCRIPT_DESC = 'Hamster.db Reporting Utility'
SCRIPT_VERS = 'X' # '0.1'

class HR_Argparser(argparse_wrap.ArgumentParser_Wrap):

	all_report_types = set([
		'all',
		'summary',
		'weekly_summary',
		'sprint_summary',
		'daily',
		'weekly',
		'activity',
		'category',
		'totals',
		'satsun',
		'sprint',
		'daily-activity',
		'daily-category',
		'daily-totals',
		'weekly-satsun',
		'weekly-sprint',
		'weekly-activity',
		'weekly-category',
		'weekly-activity-satsun',
		'weekly-category-satsun',
		'weekly-activity-sprint',
		'weekly-category-sprint',
	])

	weekly_report = set([
		'daily-activity',
		'daily-category',
		'daily-totals',
		'weekly-activity-satsun',
		'weekly-category-satsun',
	])

	sprint_report = set([
		'daily-activity',
		'daily-category',
		'daily-totals',
		'weekly-activity-sprint',
		'weekly-category-sprint',
	])

	# 0 is Sunday; 6 is Saturday.
	weekday_lookup_1_char = {
		#'s': 0,
		'm': 1,
		#'t': 2,
		'w': 3,
		#'t': 4,
		'f': 5,
		#'s': 6,
	}
	weekday_lookup_2_chars = {
		'su': 0,
		'mo': 1,
		'tu': 2,
		'we': 3,
		'th': 4,
		'fr': 5,
		'sa': 6,
	}

	def __init__(self):
		argparse_wrap.ArgumentParser_Wrap.__init__(self,
			description=SCRIPT_DESC,
			script_name=None,
			script_version=SCRIPT_VERS,
			usage=None)

	def prepare(self):
		argparse_wrap.ArgumentParser_Wrap.prepare(self)

		self.add_argument('-b', '--beg-time', '--from', dest='time_beg',
			type=str, metavar='BEG. DATE', default=None
		)
		self.add_argument('-e', '--end-time', '--to', dest='time_end',
			type=str, metavar='END DATE', default=None
		)

		self.add_argument('-w', '--week-starts', dest='week_starts',
			type=str, metavar='DAY WEEK STARTS', default=None
		)
		self.add_argument('-W', '--print-1-week', dest='sprint_1_week',
			type=int, metavar='SPRINT_1_WEEK', default=0
		)

		# LATER/#XXX: day-starts feature.
		self.add_argument('-d', '--day-starts', dest='day_starts',
			type=str, metavar='DAY WEEK STARTS', default=None
		)

		self.add_argument('-c', '--categories', dest='categories',
			action='append', type=str, metavar='CATEGORY',
		)

		self.add_argument('-a', '--activities', dest='activities',
			action='append', type=str, metavar='ACTIVITY',
		)

		self.add_argument('-t', '--tag', dest='tags',
			action='append', type=str, metavar='TAG',
		)

		self.add_argument('--description', dest='description',
			action='append', type=str, metavar='DESCRIPTION',
		)

		self.add_argument('-s', '--search', '-q', '--query', dest='query',
			action='append', type=str, metavar='QUERY',
		)

		self.add_argument('-0', '--today', dest='prev_weeks',
			action='store_const', const=0,
		)
		self.add_argument('-1', '--current-week', dest='prev_weeks',
			action='store_const', const=1,
		)
		self.add_argument('-2', '--last-full-week', dest='prev_weeks',
			action='store_const', const=2,
		)
		self.add_argument('-4', '--current-month', dest='prev_weeks',
			action='store_const', const=4,
		)
		self.add_argument('-5', '--last-month', dest='prev_weeks',
			action='store_const', const=5,
		)

		# LATER/#XXX: Check for gaps feature.
		self.add_argument('-g', '--gaps', dest='check_gaps',
			action='store_true', default=False,
		)

		self.add_argument('-D', '--data', dest='hamster_db_path',
			type=str, metavar='HAMSTER_DB_PATH', default=None
		)

		self.add_argument('-A', '--list-all', dest='do_list_all',
			action='store_true', default=False,
		)

		self.add_argument('-r', '--report-types', dest='do_list_types',
			action='append', type=str, metavar='REPORT_TYPE',
			choices=HR_Argparser.all_report_types,
		)

		self.add_argument('-S', '--show-sql', dest='show_sql',
			action='store_true', default=False,
		)

		self.add_argument('-vv', '--verbose', dest='be_verbose',
			action='store_true', default=False,
		)

	def verify(self):
		ok = argparse_wrap.ArgumentParser_Wrap.verify(self)

		if self.cli_opts.be_verbose:
			log.setLevel(logging.DEBUG)
		else:
			log.setLevel(logging.WARNING)

		if self.cli_opts.week_starts:
			try:
				self.cli_opts.week_starts = int(self.cli_opts.week_starts)
				if (
					(self.cli_opts.week_starts < 0)
					or (self.cli_opts.week_starts > 6)
					):
						log.fatal('"%s" is not a valid weekday number (0-6)' % (
							self.cli_opts.week_starts,)
						)
						ok = False
			except ValueError:
				if len(self.cli_opts.week_starts) == 1:
					try:
						self.cli_opts.week_starts = HR_Argparser.weekday_lookup_1_char[
							self.cli_opts.week_starts.lower()
						]
					except KeyError:
						log.fatal('"%s" is not a valid weekday' % (
							self.cli_opts.week_starts,)
						)
						ok = False
				else:
					week_abbrev = self.cli_opts.week_starts.lower()[:2]
					try:
						self.cli_opts.week_starts = HR_Argparser.weekday_lookup_2_chars[
							week_abbrev
						]
					except KeyError:
						log.fatal('"%s" is not a valid weekday' % (week_abbrev,))
						ok = False
		else:
			self.cli_opts.week_starts = 0

		if self.cli_opts.day_starts:
			# day_starts is the time of day that each 24 hours starts.
			# Default to midnight in your local timezone.
			log.fatal('LATER/#XXX: Implement this feature.')
			ok = False

		if self.cli_opts.hamster_db_path is None:
			self.cli_opts.hamster_db_path = (
				'%s/.local/share/hamster-applet/hamster.db'
				% (os.path.expanduser('~'),)
			)

		if self.cli_opts.do_list_types is None:
			self.cli_opts.do_list_types = HR_Argparser.weekly_report
		else:
			self.cli_opts.do_list_types = set(self.cli_opts.do_list_types)
			if 'weekly_summary' in self.cli_opts.do_list_types:
				self.cli_opts.do_list_types = self.cli_opts.do_list_types.union(
					HR_Argparser.weekly_report
				)
			if 'sprint_summary' in self.cli_opts.do_list_types:
				self.cli_opts.do_list_types = self.cli_opts.do_list_types.union(
					HR_Argparser.sprint_report
				)

		if self.cli_opts.prev_weeks is not None:
			# 0: today, 1: this week, 2: this week and last, 4: month, 5: 2 months.
			#today = time.time()
			today = datetime.date.today()
			if self.cli_opts.time_end is not None:
				log.fatal('Overriding time_end with today because prev_weeks.')
			# FIXME: This makes -0 return zero results, i.e., nothing hits for
			#        today. Which probably means < time_end and not <=, is that okay?
			#self.cli_opts.time_end = today.isoformat()
			self.cli_opts.time_end = today + datetime.timedelta(1)
			if self.cli_opts.time_beg is not None:
				log.fatal('Overriding time_beg with calculated because prev_weeks.')
			if self.cli_opts.prev_weeks == 0:
				start_date = today - datetime.timedelta(1)
				#start_date = today
				self.cli_opts.time_beg = today.isoformat()
				#self.cli_opts.time_beg = start_date.isoformat()
			else:
				#self.cli_opts.time_end = today.isoformat()
				# Python says Monday is 0 and Sunday is 6;
				# Sqlite3 says Sunday 0 and Saturday 6.
				weekday = (today.weekday() + 1) % 7
				days_ago = abs(weekday - self.cli_opts.week_starts)
				if self.cli_opts.prev_weeks == 1:
					# Calculate back to week start.
					start_date = today - datetime.timedelta(days_ago)
				elif self.cli_opts.prev_weeks == 2:
					# Calculate to two weeks backs ago.
					start_date = today - datetime.timedelta(7 + days_ago)
				elif self.cli_opts.prev_weeks == 4:
					start_date = today.replace(day=1)
				elif self.cli_opts.prev_weeks == 5:
					year = today.year
					month = today.month - 1
					if not month:
						year -= 1
						month = 12
					start_date = datetime.date(year, month, 1)
				else:
					log.fatal(
						'Precanned time span value should be one of: 0, 1, 2, 4, 5; not %s'
						% (self.cli_opts.prev_weeks,)
					)
				self.cli_opts.time_beg = start_date.isoformat()

		return ok

class Hamsterer(argparse_wrap.Simple_Script_Base):

	def __init__(self, argparser=HR_Argparser):
		argparse_wrap.Simple_Script_Base.__init__(self, argparser)

	def go_main(self):
		log.debug('go_main: cli_opts: %s' % (self.cli_opts,))

		try:
			self.conn = sqlite3.connect(self.cli_opts.hamster_db_path)
			self.curs = self.conn.cursor()
		except Exception as err:
			log.fatal('Report failed: %s' % (str(err),))
			sys.exit(1)

		if ((self.cli_opts.do_list_all)
			or ('all' in self.cli_opts.do_list_types)
		):
			self.list_all()

		unknown_types = self.cli_opts.do_list_types.difference(HR_Argparser.all_report_types)
		if unknown_types:
			log.warning('Unknown print list display output types: %s' % (unknown_types,))

		# MAYBE: Go through self.cli_opts.do_list_types in order and print in that order.

		if (('daily' in self.cli_opts.do_list_types)
			or ('activity' in self.cli_opts.do_list_types)
			or ('daily-activity' in self.cli_opts.do_list_types)
		):
			self.list_daily_per_activity()

		if (('daily' in self.cli_opts.do_list_types)
			or ('category' in self.cli_opts.do_list_types)
			or ('daily-category' in self.cli_opts.do_list_types)
		):
			self.list_daily_per_category()

		if (('daily' in self.cli_opts.do_list_types)
			or ('totals' in self.cli_opts.do_list_types)
			or ('daily-totals' in self.cli_opts.do_list_types)
		):
			self.list_daily_totals()

		if (('weekly' in self.cli_opts.do_list_types)
			or ('activity' in self.cli_opts.do_list_types)
			or ('satsun' in self.cli_opts.do_list_types)
			or ('weekly-activity' in self.cli_opts.do_list_types)
			or ('weekly-satsun' in self.cli_opts.do_list_types)
			or ('weekly-activity-satsun' in self.cli_opts.do_list_types)
		):
			self.list_satsun_weekly_per_activity()

		if (('weekly' in self.cli_opts.do_list_types)
			or ('category' in self.cli_opts.do_list_types)
			or ('satsun' in self.cli_opts.do_list_types)
			or ('weekly-category' in self.cli_opts.do_list_types)
			or ('weekly-satsun' in self.cli_opts.do_list_types)
			or ('weekly-category-satsun' in self.cli_opts.do_list_types)
		):
			self.list_satsun_weekly_per_category()

		if (('weekly' in self.cli_opts.do_list_types)
			or ('totals' in self.cli_opts.do_list_types)
			or ('satsun' in self.cli_opts.do_list_types)
			or ('weekly-totals' in self.cli_opts.do_list_types)
			or ('weekly-satsun' in self.cli_opts.do_list_types)
			or ('weekly-totals-satsun' in self.cli_opts.do_list_types)
		):
			self.list_satsun_weekly_totals()

		if (('weekly' in self.cli_opts.do_list_types)
			or ('activity' in self.cli_opts.do_list_types)
			or ('sprint' in self.cli_opts.do_list_types)
			or ('weekly-activity' in self.cli_opts.do_list_types)
			or ('weekly-sprint' in self.cli_opts.do_list_types)
			or ('weekly-activity-sprint' in self.cli_opts.do_list_types)
		):
			self.list_sprint_weekly_per_activity()

		if (('weekly' in self.cli_opts.do_list_types)
			or ('category' in self.cli_opts.do_list_types)
			or ('sprint' in self.cli_opts.do_list_types)
			or ('weekly-category' in self.cli_opts.do_list_types)
			or ('weekly-sprint' in self.cli_opts.do_list_types)
			or ('weekly-category-sprint' in self.cli_opts.do_list_types)
		):
			self.list_sprint_weekly_per_category()

		if (('weekly' in self.cli_opts.do_list_types)
			or ('totals' in self.cli_opts.do_list_types)
			or ('sprint' in self.cli_opts.do_list_types)
			or ('weekly-totals' in self.cli_opts.do_list_types)
			or ('weekly-sprint' in self.cli_opts.do_list_types)
			or ('weekly-totals-sprint' in self.cli_opts.do_list_types)
		):
			self.list_sprint_weekly_totals()

		self.conn.close()
		self.curs = None
		self.conn = None

	# All the SQL functions fit to output.

	# NOTE: Ideally, we'd not trust user input and all self.curs.execute
	#       with a SQL command containing '?'s, and the user input would
	#       be passed as a list of strings so sqlite3 can defend against
	#       injection. Alas, the python3.4 sqlite3 library on Mint 17.2 is
	#         >>> import sqlite3 ; print(sqlite3.sqlite_version)
	#         3.8.2
	#       but we're really running
	#         $ sqlite3 --version
	#         3.10.1 2016-01-13 21:41:56
	#       and the printf command was added in 3.8.3. tl;dr too late ha
	SQL_EXTERNAL = True
	sqlite_v = sqlite3.sqlite_version.split('.')
	if (
		(int(sqlite_v[0]) > 3)
		or (int(sqlite_v[1]) > 8)
		or ((int(sqlite_v[1]) == 8) and (int(sqlite_v[2]) > 2))
	):
		SQL_EXTERNAL = False

	# A hacky way to add leading spaces/zeros: use substr.
	# CAVEAT: This hack will strip characters if number of characters exceeds
	# the substr bounds. So leave one more than expected -- if you don't see
	# a leading blank, be suspicious.
	SQL_DURATION="substr('       ' || printf('%.3f', sum(duration)), -8, 8)"

	def setup_sql_day_of_week(self):
		self.sql_day_of_week = (
			"""
			CASE CAST(strftime('%w', start_time) AS INTEGER)
				WHEN 0 THEN 'sun'
				WHEN 1 THEN 'mon'
				WHEN 2 THEN 'tue'
				WHEN 3 THEN 'wed'
				WHEN 4 THEN 'thu'
				WHEN 5 THEN 'fri'
					   ELSE 'sat'
			END AS day_of_week
			"""
		)
		self.str_params['SQL_DAY_OF_WEEK'] = self.sql_day_of_week

	def setup_sql_dates(self):
		self.sql_beg_date = ''
		self.sql_beg_date_ = ''
		if self.cli_opts.time_beg:
			self.sql_beg_date = "AND facts.start_time >= datetime(?)"
			self.sql_beg_date_ = (
				"AND facts.start_time >= datetime('%s')"
				% (self.cli_opts.time_beg,)
			)
			self.sql_params.append(self.cli_opts.time_beg)
		if not Hamsterer.SQL_EXTERNAL:
			self.str_params['SQL_BEG_DATE'] = self.sql_beg_date
		else:
			self.str_params['SQL_BEG_DATE'] = self.sql_beg_date_

		self.sql_end_date = ''
		self.sql_end_date_ = ''
		if self.cli_opts.time_end:
			self.sql_end_date = "AND facts.start_time < datetime(?)"
			self.sql_end_date_ = (
				"AND facts.start_time < datetime('%s')"
				% (self.cli_opts.time_end,)
			)
			self.sql_params.append(self.cli_opts.time_end)
		if not Hamsterer.SQL_EXTERNAL:
			self.str_params['SQL_END_DATE'] = self.sql_end_date
		else:
			self.str_params['SQL_END_DATE'] = self.sql_end_date_

	# LATER/#XXX:
	def setup_sql_week_starts(self):
		self.str_params['SQL_WEEK_STARTS'] = self.cli_opts.week_starts

	def setup_sql_categories(self):
		self.sql_categories = ''
		self.sql_categories_ = ''
		if self.cli_opts.categories:
			qmark_list = ','.join(['?' for x in self.cli_opts.categories])
			self.sql_categories = (
				#"AND categories.name in (%s)" % (qmark_list,)
				"AND categories.search_name in (%s)" % (qmark_list,)
			)
			name_list = ','.join(["'%s'" % (x,) for x in self.cli_opts.categories])
			self.sql_categories_ = (
				#" AND categories.name in (%s)" % (name_list,)
				" AND categories.search_name in (%s)" % (name_list,)
			)
			self.sql_params.append(self.cli_opts.categories)
		if not Hamsterer.SQL_EXTERNAL:
			self.str_params['REPORT_CATEGORIES'] = self.sql_categories
		else:
			self.str_params['REPORT_CATEGORIES'] = self.sql_categories_

	def setup_sql_activities(self):
		self.sql_activities = ''
		self.sql_activities_ = ''
		if self.cli_opts.activities:
			qmark_list = ','.join(['?' for x in self.cli_opts.activities])
			self.sql_activities = (
				"AND activities.name in (%s)" % (qmark_list,)
				#"AND activities.search_name in (%s)" % (qmark_list,)
			)
			name_list = ','.join(["'%s'" % (x,) for x in self.cli_opts.activities])
			self.sql_activities_ = (
				" AND activities.name in (%s)" % (name_list,)
				#" AND activities.search_name in (%s)" % (name_list,)
			)
			# We probably don't need/want to be strict:
			#	self.sql_activities = (
			#		"""
			#		AND (0
			#			%s
			#		)
			#		"""
			#		% (''.join(["OR activities.name LIKE '%%?%%'"
			#					for x in self.cli_opts.activities]),
			#		)
			#	)
			self.sql_activities_ = (
				"""
				AND (0
					%s
				)
				"""
				% (''.join(["OR activities.name LIKE '%%%s%%'" % (x,)
							for x in self.cli_opts.activities]),
				)
			)
			self.sql_params.append(self.cli_opts.activities)
		if not Hamsterer.SQL_EXTERNAL:
			self.str_params['SQL_ACTIVITY_NAME'] = self.sql_activities
		else:
			self.str_params['SQL_ACTIVITY_NAME'] = self.sql_activities_

	def print_output_generic_fcn_name(self, sql_select, use_header=False):
		if self.cli_opts.show_sql:
			log.debug(sql_select)

		if not Hamsterer.SQL_EXTERNAL:
			try:
				self.curs.execute(sql_select, self.sql_params)
				print(self.cur.fetchall())
			except Exception as err:
				log.fatal('SQL statement failed: %s' % (str(err),))
				log.fatal('sql_select: %s' % (sql_select,))
				log.fatal('sql_params: %s' % (self.sql_params,))
		else:
			# sqlite3 output options: -column -csv -html -line -list
			try:
				sql_args = ['sqlite3',]
				if use_header:
					sql_args.append('-header')
				sql_args += [
					self.cli_opts.hamster_db_path,
					#'"%s;"' % (sql_select,),
					'%s;' % (sql_select,),
				]
				# Send stderr to /dev/null to suppress:
				#   -- Loading resources from /home/landonb/.sqliterc
				#   Error: near line 11: libspatialite.so.5.so: cannot open shared object file:
				#    No such file or directory
				# Hrm, I thought you could capture output in ret to process it
				# with run(), but shell=True dumps me on the sqlite3 prompt.
				if False:
					ret = subprocess.run(sql_args, stderr=subprocess.DEVNULL)
				if False:
					# We could use check_output to collect output lines.
					#ret = subprocess.check_output(sql_args, stderr=subprocess.DEVNULL)
					# DEBUGGING: Run without stderr redirected.
					# FIXME: Redirect STDERR so it doesn't print but so can can complain
					ret = subprocess.check_output(sql_args)
					ret = ret.decode("utf-8")
					lines = ret.split('\n')
					n_facts = 0
					for line in lines:
						if line:
							print(line)
							n_facts += 1
					#print('No. facts found: %d' % (n_facts,))
				if True:
					ret = subprocess.run(sql_args, stderr=subprocess.PIPE)
					# ret.stdout is None because everything went to stdout.
					errlns = ret.stderr.decode("utf-8").split('\n')
					# These are some stderrs [lb's] .sqliterc trigger...
					re_loading_resource = re.compile(r'^-- Loading resources from /home/.*/.sqliterc$')
					re_error_libspatialite = re.compile(
	r'^Error: near line .*: libspatialite.*: cannot open shared object file: No such file or directory$'
					)
					errs_found = False
					for errln in errlns:
						if errln and not (
							re_loading_resource.match(errln)
							or re_error_libspatialite.match(errln)
						):
							errs_found = True
					if errs_found:
						print('Errors found!')
						print(errlns)
			except subprocess.CalledProcessError as err:
				log.fatal('Sql no bueno: %s' % (sql_select,))
				# Why isn't this printing by itself?
				log.fatal('err.output: %s' % (err.output,))
				raise

	def list_all(self):
		self.sql_params = []
		self.str_params = {}
		self.setup_sql_day_of_week()
		self.setup_sql_categories()
		self.setup_sql_dates()
		self.setup_sql_activities()
		sql_select = """
			SELECT
				%(SQL_DAY_OF_WEEK)s
				, strftime('%%Y-%%m-%%d', facts.start_time)
				, strftime('%%H:%%M', facts.start_time)
				, strftime('%%H:%%M', facts.end_time)
				, substr(' ' || printf('%%.3f',
					24.0 * (julianday(facts.end_time) - julianday(facts.start_time))
					), -10, 10)
				AS duration
				, activities.name AS activity_name
				, facts.description
				--, strftime('%%Y-%%j', facts.start_time) AS yrjul
			FROM facts
			JOIN activities ON (activities.id = facts.activity_id)
			JOIN categories ON (categories.id = activities.category_id)
			WHERE 1
				%(REPORT_CATEGORIES)s
				%(SQL_BEG_DATE)s
				%(SQL_END_DATE)s
				%(SQL_ACTIVITY_NAME)s
			ORDER BY facts.start_time, facts.id desc
		;
		""" % self.str_params
		print()
		print('ALL FACTS')
		print('=========')
		self.print_output_generic_fcn_name(sql_select)

	def setup_sql_fact_durations(self):
		self.sql_params = []
		self.str_params = {}
		self.setup_sql_day_of_week()
		self.setup_sql_week_starts()
		self.setup_sql_categories()
		self.setup_sql_dates()
		self.setup_sql_activities()
		# Note: julianday returns a float, so multiple by units you want,
		#       *24 gives you hours, or *86400 gives you seconds.
		self.sql_fact_durations = """
			SELECT
				24.0 * (julianday(facts.end_time) - julianday(facts.start_time)) AS duration
				--, strftime('%%Y-%%m-%%d', facts.start_time) AS yrjul
				, strftime('%%Y-%%j', facts.start_time) AS yrjul
-- ??? try day_of_week2
				, cast(strftime('%%w', facts.start_time) as integer) as day_of_week
				, cast(julianday(start_time) as integer) as julian_day_group
				, case when (cast(strftime('%%w', facts.start_time) as integer) - %(SQL_WEEK_STARTS)s) >= 0
				  then (cast(strftime('%%w', facts.start_time) as integer) - %(SQL_WEEK_STARTS)s)
				  else (7 - %(SQL_WEEK_STARTS)s + cast(strftime('%%w', facts.start_time) as integer))
				  end as psuedo_week_offset
				, categories.search_name AS category_name
				--, categories.name AS category_name
				, activities.name AS activity_name
				--, activities.search_name AS activity_name
				, facts.activity_id
				, facts.start_time
				, tag_names
			--FROM facts
			FROM (
				SELECT
					max(facts.id) AS max_id
					, group_concat(tags.name) AS tag_names
				FROM facts
				LEFT OUTER JOIN fact_tags ON (facts.id = fact_tags.fact_id)
				LEFT OUTER JOIN tags ON (fact_tags.tag_id = tags.id)
				WHERE 1
					%(SQL_BEG_DATE)s
					%(SQL_END_DATE)s
				GROUP BY start_time, tags.id
			) AS max
			JOIN facts ON (max.max_id = facts.id)
			JOIN activities ON (activities.id = facts.activity_id)
			JOIN categories ON (categories.id = activities.category_id)
			WHERE 1
				%(REPORT_CATEGORIES)s
				%(SQL_BEG_DATE)s
				%(SQL_END_DATE)s
				%(SQL_ACTIVITY_NAME)s
			GROUP BY facts.id
			ORDER BY facts.start_time
		""" % self.str_params
		self.str_params['SQL_FACT_DURATIONS'] = self.sql_fact_durations
		self.str_params['SQL_DURATION'] = Hamsterer.SQL_DURATION

	def list_daily_per_activity(self):
		print()
		print('DAILY ACTIVITY TOTALS')
		print('=====================')
		self.setup_sql_fact_durations()
		sql_select = """
			SELECT
				%(SQL_DAY_OF_WEEK)s
				, strftime('%%Y-%%m-%%d', min(julianday(start_time)))
				, %(SQL_DURATION)s as duration
				--, category_name
				, substr('            ' || category_name, -12, 12)
				, activity_name
				, tag_names
			FROM (%(SQL_FACT_DURATIONS)s) AS project_time
			GROUP BY yrjul, activity_id
			ORDER BY start_time, activity_name
		""" % self.str_params
		self.print_output_generic_fcn_name(sql_select)

	def list_daily_per_category(self):
		print()
		print('DAILY CATEGORY TOTALS')
		print('=====================')
		self.setup_sql_fact_durations()
		sql_select = """
        SELECT
			%(SQL_DAY_OF_WEEK)s
            , strftime('%%Y-%%m-%%d', min(julianday(start_time))) AS start_time
            , %(SQL_DURATION)s AS duration
            , category_name
			, tag_names
        FROM (%(SQL_FACT_DURATIONS)s) AS project_time
        GROUP BY yrjul, category_name
        ORDER BY start_time, category_name
		""" % self.str_params
		self.print_output_generic_fcn_name(sql_select)

	def list_daily_totals(self):
		print()
		print('DAILY TOTALS')
		print('============')
		self.setup_sql_fact_durations()
		sql_select = """
        SELECT
			%(SQL_DAY_OF_WEEK)s
            , strftime('%%Y-%%m-%%d', min(julianday(start_time)))
            , %(SQL_DURATION)s AS duration
			, tag_names
        FROM (%(SQL_FACT_DURATIONS)s) AS project_time
        GROUP BY yrjul
        ORDER BY start_time
		""" % self.str_params
		self.print_output_generic_fcn_name(sql_select)

	def list_weekly_wrap(self,
		sql_julian_day_of_year,
		group_by_categories=False,
		group_by_activities=False,
		week_num_unit='sprint_num',
	):
		self.setup_sql_fact_durations()
		self.str_params['SQL_JULIAN_WEEK'] = "cast(%s / 7 as integer)" % (
			sql_julian_day_of_year,
		)
		group_bys = ['julianweek',]
		sql_select_extra = ''
		sql_order_by_extra = ''
		#if self.cli_opts.categories or self.cli_opts.query:
		group_bys.append('tag_names')
		if group_by_categories:
			group_bys.append('category_name')
			sql_select_extra += ", substr('            ' || category_name, -12, 12)"
			sql_order_by_extra += ', category_name'
		if group_by_activities:
			group_bys.append('activity_name')
			sql_select_extra += ', activity_name'
			sql_order_by_extra += ', activity_name'
		if False: # Something like this?:
			if self.cli_opts.activities or self.cli_opts.query:
				group_bys.append('activity')
			if self.cli_opts.tags or self.cli_opts.query:
				group_bys.append('tags')
			if self.cli_opts.query:
				group_bys.append('query')
		sql_select_extra += ', tag_names'
		sql_group_by = "GROUP BY %s" % (', '.join(group_bys),)
		self.str_params['SPRINT_1_WEEK'] = self.cli_opts.sprint_1_week
		self.str_params['WEEK_NUM_UNIT'] = week_num_unit
		self.str_params['SELECT_EXTRA'] = sql_select_extra
		self.str_params['ORDER_BY_EXTRA'] = sql_order_by_extra
		self.str_params['SQL_GROUP_BY'] = sql_group_by
		sql_select = """
			SELECT
				%(SQL_DAY_OF_WEEK)s
				, strftime('%%Y-%%m-%%d', start_time) AS start_date
				--, julianweek
				, julianweek - %(SPRINT_1_WEEK)s AS %(WEEK_NUM_UNIT)s
				, duration
				%(SELECT_EXTRA)s
			FROM (
				SELECT
					min(julianday(start_time)) AS start_time
					, %(SQL_JULIAN_WEEK)s AS julianweek
					, %(SQL_DURATION)s AS duration
					, tag_names
					%(ORDER_BY_EXTRA)s
				FROM (%(SQL_FACT_DURATIONS)s) AS inner
				%(SQL_GROUP_BY)s
			) AS project_time
			ORDER BY start_date %(ORDER_BY_EXTRA)s
			""" % self.str_params
		self.print_output_generic_fcn_name(sql_select, use_header=True)
		#self.print_output_generic_fcn_name(sql_select, use_header=False)

	SQL_JDOY_OFFSET_SUNSAT = (
		"""(
		julianday(start_time)
		- julianday(strftime('%Y-01-01', start_time))
		+ cast(strftime('%w', strftime('%Y-01-01', start_time)) AS integer)
		)"""
	)

	def list_satsun_weekly_wrap(self, subtitle, cats, acts):
		print()
		print('SUN-SAT WEEKLY %s TOTALS' % (subtitle,))
		print('===============%s=======' % ('=' * len(subtitle),))
		sql_julian_day_of_year = Hamsterer.SQL_JDOY_OFFSET_SUNSAT
		self.list_weekly_wrap(sql_julian_day_of_year,
			group_by_categories=cats,
			group_by_activities=acts,
			week_num_unit='week_num'
		)

	def list_satsun_weekly_per_activity(self):
		self.list_satsun_weekly_wrap('ACTIVITY', True, True)

	def list_satsun_weekly_per_category(self):
		self.list_satsun_weekly_wrap('CATEGORY', True, False)

	def list_satsun_weekly_totals(self):
		self.list_satsun_weekly_wrap('TOTAL', False, False)

	SQL_JDOY_OFFSET = (
		"""(
		julianday(start_time)
		- psuedo_week_offset
		+ 7
		- julianday(strftime('%Y-01-01', start_time))
		)"""
	)

	def list_sprint_weekly_wrap(self, subtitle, cats, acts):
		print()
		print('SPRINT WEEKLY %s TOTALS' % (subtitle,))
		print('==============%s=======' % ('=' * len(subtitle),))
		sql_julian_day_of_year = Hamsterer.SQL_JDOY_OFFSET
		self.list_weekly_wrap(sql_julian_day_of_year,
			group_by_categories=cats,
			group_by_activities=acts,
			week_num_unit='sprint_num'
		)

	def list_sprint_weekly_per_activity(self):
		self.list_sprint_weekly_wrap('ACTIVITY', True, True)

	def list_sprint_weekly_per_category(self):
		self.list_sprint_weekly_wrap('CATEGORY', True, False)

	def list_sprint_weekly_totals(self):
		self.list_sprint_weekly_wrap('TOTAL', False, False)

if (__name__ == '__main__'):
	hr = Hamsterer()
	hr.go()

