#!/usr/bin/env python3.5
# Last Modified: 2016.02.08 /coding: utf-8
# Copyright: © 2016 Landon Bouma.
#  vim:tw=0:ts=4:sw=4:noet

my_cmds="""

hamster_report.py -c 'excensus' -c 'exo-tickets' -r all -S
	


"""

# LATER/#XXX: day-starts feature.
# LATER/#XXX: Check for gaps feature.
# LATER/#XXX: Double-check time math is inclusive and doesn't round down on minutes...
#             though this might make a day's activities greater than exactly 24 hours?
# LATER/#XXX: Option to print comments/description when itemizing.
#             - Which means using list-all with a search query and maybe dates...
# LATER/#XXX: --only-date or something to specify a 24 hour period?

import os
import sys

import sqlite3
import subprocess

# MAYBE: Install pyoilerplate to site-packages and treat as 3d party lib.
sys.path.append('%s/libmypy' % (os.path.abspath(sys.path[0]),))
from libmypy import argparse_wrap

import logging
from libmypy import logging2
logging2.init_logging(logging.DEBUG, log_to_console=True)
log = logging.getLogger('argparse_wrap')

SCRIPT_DESC = 'Hamster.db Reporting Utility'
SCRIPT_VERS = '0.1'

class HR_Argparser(argparse_wrap.ArgumentParser_Wrap):

	summary_report = set([
		'day', 'cats', 'for', 'the', 'catted', 'offset',
	])

	all_report_types = summary_report.union(set(['all',]))

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

	def __init__(self, description=SCRIPT_DESC, script_version=SCRIPT_VERS, usage=None):
		argparse_wrap.ArgumentParser_Wrap.__init__(self, description, usage)

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

	def verify(self):
		ok = argparse_wrap.ArgumentParser_Wrap.verify(self)

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
			self.cli_opts.do_list_types = HR_Argparser.summary_report
		else:
			self.cli_opts.do_list_types = set(self.cli_opts.do_list_types)

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

#		self.setup_sql_tidbits()

		if ((self.cli_opts.do_list_all)
			or ('all' in self.cli_opts.do_list_types)
		):
			self.list_all()

		unknown_types = self.cli_opts.do_list_types.difference(HR_Argparser.all_report_types)
		if unknown_types:
			log.warning('Unknown print list display output types: %s' % (unknown_types,))

		if ((self.cli_opts.do_list_types.intersection(HR_Argparser.summary_report))
			or ('day' in self.cli_opts.do_list_types)
		):
			self.list_for_day()

		if ((self.cli_opts.do_list_types.intersection(HR_Argparser.summary_report))
			or ('cats' in self.cli_opts.do_list_types)
		):
			self.list_for_week_categories()

		if ((self.cli_opts.do_list_types.intersection(HR_Argparser.summary_report))
			or ('for' in self.cli_opts.do_list_types)
		):
			self.list_for_week()

		if ((self.cli_opts.do_list_types.intersection(HR_Argparser.summary_report))
			or ('the' in self.cli_opts.do_list_types)
		):
			self.list_the_week()

		if ((self.cli_opts.do_list_types.intersection(HR_Argparser.summary_report))
			or ('catted' in self.cli_opts.do_list_types)
		):
			self.list_week_offset_catted()

		if ((self.cli_opts.do_list_types.intersection(HR_Argparser.summary_report))
			or ('offset' in self.cli_opts.do_list_types)
		):
			self.list_week_offset()

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

	SQL_DAY_OF_WEEK = (
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
#	def setup_sql_tidbits(self):
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

	def setup_sql_dates(self):
		self.sql_beg_date = ''
		self.sql_beg_date_ = ''
		if self.cli_opts.time_beg:
			self.sql_beg_date = "AND facts.start_time >= datetime(?)"
			self.sql_beg_date_ = (
				"AND facts.start_time >= datetime(%s)"
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
				"AND facts.start_time < datetime(%s)"
				% (self.cli_opts.time_end,)
			)
			self.sql_params.append(self.cli_opts.time_end)
		if not Hamsterer.SQL_EXTERNAL:
			self.str_params['SQL_END_DATE'] = self.sql_end_date
		else:
			self.str_params['SQL_END_DATE'] = self.sql_end_date_

	# LATER/#XXX:
	def setup_sql_week_starts(self):
		self.cli_opts.week_starts = ''
		self.cli_opts.week_starts_ = ''

	def setup_sql_categories(self):
		self.sql_categories = ''
		self.sql_categories_ = ''
		if self.cli_opts.categories:
			qmark_list = ','.join(['?' for x in self.cli_opts.categories])
			self.sql_categories = (
				"AND categories.search_name in (%s)" % (qmark_list,)
			)
			name_list = ','.join(["'%s'" % (x,) for x in self.cli_opts.categories])
			self.sql_categories_ = (
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
			)
			name_list = ','.join(["'%s'" % (x,) for x in self.cli_opts.activities])
			self.sql_activities_ = (
				" AND activities.name in (%s)" % (name_list,)
			)
# FIXME: Loose or Strict?
			self.sql_activities = (
				"""
				AND (0
					%s
				)
				"""
				% (''.join(["OR activities.name LIKE '%%?%%'"
							for x in self.cli_opts.activities]),
				)
			)
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

	def print_output_generic_fcn_name(self, sql_select):
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
			try:
				sql_args = [
					'sqlite3',
					self.cli_opts.hamster_db_path,
					#'"%s;"' % (sql_select,),
					'%s;' % (sql_select,),
				]
				##ret = subprocess.check_output(sql_args)
				#ret = subprocess.check_output(sql_args, stderr=subprocess.STDOUT)
				#print('%s' % (str(ret),))
				ret = subprocess.run(sql_args)
			except subprocess.CalledProcessError as err:
				log.fatal('Sql no bueno: %s' % (sql_select,))
				# Why isn't this printing by itself?
				log.fatal('err.output: %s' % (err.output,))
				raise

	def list_all(self):
		self.sql_params = []
		self.str_params = {
			'SQL_DAY_OF_WEEK': Hamsterer.SQL_DAY_OF_WEEK,
		}
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
				  ), -10, 10) AS duration
				, activities.name
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
		self.print_output_generic_fcn_name(sql_select)

	def list_for_day(self):
		self.sql_params = []
		pass

	def list_for_week_categories(self):
		self.sql_params = []
		pass

	def list_for_week(self):
		self.sql_params = []
		pass

	def list_the_week(self):
		self.sql_params = []
		pass

	def list_week_offset_catted(self):
		self.sql_params = []
		pass

	def list_week_offset(self):
		self.sql_params = []
		pass


juicy="""

# USAGE:
#
# ./hamster_report.sh [ YYYY-MM-HH [ YYYY-MM-HH ] ]


# FIXME: Double-check time math is inclusive and doesn't round down on minutes...
#        though this might make a day's activities greater than exactly 24 hours?



# FIXME: Add cli options to control output.

# FIXME: Complain if gaps in timesheet -- every end should be another's start... except last entry.



#pushd ${HOME}/.local/share/hamster-applet &> /dev/null
HAMSTER_DB="${HOME}/.local/share/hamster-applet/hamster.db"

#BEG_DATE="2016-01-01 00:00:00"
#END_DATE="2016-01-21 00:00:00"

#SQL_WEEK_START="0" # 
#SQL_WEEK_START="1" # Monday
#SQL_WEEK_START="2" # 
#SQL_WEEK_START="3" # 
SQL_WEEK_START="4" # Thursday
#SQL_WEEK_START="5" # 
#SQL_WEEK_START="6" # Saturday

SPRINT_1_WEEK="-2"

REPORT_CATEGORIES="
AND (
    0
    OR categories.search_name = 'excensus'
    OR categories.search_name = 'exo-tickets'
)"

# ======================================================

if [[ -n $1 ]]; then
    BEG_DATE=$1
fi
if [[ -n $2 ]]; then
    END_DATE=$2
fi

SQL_BEG_DATE=""
if [[ ${BEG_DATE} != '' ]]; then
    SQL_BEG_DATE="AND facts.start_time >= datetime('${BEG_DATE}')"
fi

SQL_END_DATE=""
if [[ ${END_DATE} != '' ]]; then
    SQL_END_DATE="AND facts.start_time < datetime('${END_DATE}')"
fi

ACTIVITY_NAME=""
#ACTIVITY_NAME="3572: Dashboard Interface Do Over: XY Chart Interface"

SQL_ACTIVITY_NAME=""
if [[ ${ACTIVITY_NAME} != '' ]]; then
    #SQL_ACTIVITY_NAME="AND activities.search_name = '${ACTIVITY_NAME}'"
    SQL_ACTIVITY_NAME="AND activities.name = '${ACTIVITY_NAME}'"
fi

# ======================================================

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

# ======================================================

SQL_DAY_OF_WEEK="
    case cast(strftime('%w', start_time) as integer)
        when 0 then 'sun'
        when 1 then 'mon'
        when 2 then 'tue'
        when 3 then 'wed'
        when 4 then 'thu'
        when 5 then 'fri'
            else 'sat'
    end as day_of_week
"

# sqlite3 output options: -column -csv -html -line -list

exo_list_all () {
    echo
    echo "ALL RECORDS"
    echo "==========="
    sqlite3 ${HAMSTER_DB} "
        SELECT
            ${SQL_DAY_OF_WEEK}
            , strftime('%Y-%m-%d', facts.start_time)
            , strftime('%H:%M', facts.start_time)
            , strftime('%H:%M', facts.end_time)
            , substr(' ' || printf('%.3f',
              24.0 * (julianday(facts.end_time) - julianday(facts.start_time))
              ), -10, 10) AS duration
            , activities.name
            , facts.description
            --, strftime('%Y-%j', facts.start_time) AS yrjul
        FROM facts
        JOIN activities ON (activities.id = facts.activity_id)
        JOIN categories ON (categories.id = activities.category_id)
        WHERE 1
            ${REPORT_CATEGORIES}
            ${SQL_BEG_DATE}
            ${SQL_END_DATE}
            ${SQL_ACTIVITY_NAME}
        ORDER BY facts.start_time, facts.id desc
    ;" 2> /dev/null
}
#exo_list_all

# Note: julianday returns a float, so multiple by units you want,
#       *24 gives you hours, or *86400 gives you seconds.

SQL_FACT_DURATIONS="
    SELECT
        24.0 * (julianday(facts.end_time) - julianday(facts.start_time)) AS duration
        --, strftime('%Y-%m-%d', facts.start_time) AS yrjul
        , strftime('%Y-%j', facts.start_time) AS yrjul
        , cast(strftime('%w', facts.start_time) as integer) as day_of_week
        , cast(julianday(start_time) as integer) as julian_day_group
        , case when (cast(strftime('%w', facts.start_time) as integer) - ${SQL_WEEK_START}) >= 0
          then (cast(strftime('%w', facts.start_time) as integer) - ${SQL_WEEK_START})
          else (7 - ${SQL_WEEK_START} + cast(strftime('%w', facts.start_time) as integer))
          end as psuedo_week_offset
        , categories.search_name
        , activities.name
        , facts.activity_id
        , facts.start_time
    --FROM facts
    FROM (
        SELECT max(id) AS max_id FROM facts
        WHERE 1
            ${SQL_BEG_DATE}
            ${SQL_END_DATE}
        GROUP BY start_time
    ) AS max
    JOIN facts ON (max.max_id = facts.id)
    JOIN activities ON (activities.id = facts.activity_id)
    JOIN categories ON (categories.id = activities.category_id)
    WHERE 1
        ${REPORT_CATEGORIES}
        ${SQL_BEG_DATE}
        ${SQL_END_DATE}
        ${SQL_ACTIVITY_NAME}
    ORDER BY facts.start_time
"

# A hacky way to add leading spaces/zeros: use substr.
# CAVEAT: This hack will strip characters if number of characters exceeds
# the substr bounds. So leave one more than expected -- if you don't see
# a leading blank, be suspicious.
SQL_DURATION="substr('       ' || printf('%.3f', sum(duration)), -8, 8)"

exo_list_for_day () {
    echo
    echo "DAILY PROJECT TOTALS"
    echo "===================="
    sqlite3 ${HAMSTER_DB} "
        SELECT
            ${SQL_DAY_OF_WEEK}
            , strftime('%Y-%m-%d', min(julianday(start_time)))
            , ${SQL_DURATION} as duration
            , name
            , search_name
        FROM (${SQL_FACT_DURATIONS}) AS project_time
        GROUP BY yrjul, activity_id
        ORDER BY start_time, name
    ;" # 2> /dev/null
}
exo_list_for_day

exo_list_for_week_categories () {
    echo
    echo "DAILY CATEGORIES"
    echo "================"
    sqlite3 ${HAMSTER_DB} "
        SELECT
            ${SQL_DAY_OF_WEEK}
            , strftime('%Y-%m-%d', min(julianday(start_time))) AS start_time
            , ${SQL_DURATION} as duration
            , search_name
        FROM (${SQL_FACT_DURATIONS}) AS project_time
        GROUP BY yrjul, search_name
        ORDER BY start_time, search_name
    ;" # 2> /dev/null
}
exo_list_for_week_categories

exo_list_for_week () {
    echo
    echo "DAILY TOTALS"
    echo "============"
    sqlite3 ${HAMSTER_DB} "
        SELECT
            ${SQL_DAY_OF_WEEK}
            , strftime('%Y-%m-%d', min(julianday(start_time)))
            , ${SQL_DURATION} as duration
        FROM (${SQL_FACT_DURATIONS}) AS project_time
        GROUP BY yrjul
        ORDER BY start_time
    ;" # 2> /dev/null
}
exo_list_for_week

exo_list_week () {
    if [[ -z $1 ]]; then
        SQL_GROUP_BY="GROUP BY julianweek"
        SELECT_SEARCH_NAME=""
    else
        SQL_GROUP_BY="GROUP BY julianweek, search_name"
        SELECT_SEARCH_NAME=", search_name"
    fi
    sqlite3 -header ${HAMSTER_DB} "
        SELECT
            ${SQL_DAY_OF_WEEK}
            , strftime('%Y-%m-%d', start_time) AS start_date
            --, julianweek
            , julianweek - ${SPRINT_1_WEEK} as sprint_num
            , duration
            ${SELECT_SEARCH_NAME}
        FROM (
            SELECT
                min(julianday(start_time)) as start_time
                , ${SQL_JULIAN_WEEK} as julianweek
                , ${SQL_DURATION} as duration
                ${SELECT_SEARCH_NAME}
            FROM (${SQL_FACT_DURATIONS}) as inner
            ${SQL_GROUP_BY}
        ) AS project_time
        ORDER BY start_date ${SELECT_SEARCH_NAME}
    ;" # 2> /dev/null
}

exo_list_the_week () {
    echo
    echo "SUN-SAT WEEKLIES"
    echo "================"
    SQL_JULIAN_DAY_OF_YEAR="(
        julianday(start_time)
        - julianday(strftime('%Y-01-01', start_time))
        + cast(strftime('%w', strftime('%Y-01-01', start_time)) as integer)
    )"
    SQL_JULIAN_WEEK="cast(${SQL_JULIAN_DAY_OF_YEAR} / 7 as integer)"
    exo_list_week
}
exo_list_the_week

exo_list_week_offset_catted () {
    echo
    echo "SPRINT WEEK CATEGORIES"
    echo "======================"
    SQL_JULIAN_DAY_OF_YEAR="(
        julianday(start_time)
        - psuedo_week_offset
        + 7
        - julianday(strftime('%Y-01-01', start_time))
    )"
    SQL_JULIAN_WEEK="cast(${SQL_JULIAN_DAY_OF_YEAR} / 7 as integer)"
    exo_list_week 1
}
exo_list_week_offset_catted

exo_list_week_offset () {
    echo
    echo "SPRINT WEEKS"
    echo "============"
    SQL_JULIAN_DAY_OF_YEAR="(
        julianday(start_time)
        - psuedo_week_offset
        + 7
        - julianday(strftime('%Y-01-01', start_time))
    )"
    SQL_JULIAN_WEEK="cast(${SQL_JULIAN_DAY_OF_YEAR} / 7 as integer)"
    exo_list_week
}
exo_list_week_offset

#popd &> /dev/null

"""





if (__name__ == '__main__'):
	hr = Hamsterer()
	hr.go()

