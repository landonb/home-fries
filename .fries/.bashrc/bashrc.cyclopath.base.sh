# File: bashrc.cyclopath.base.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.10.03
# Project Page: https://github.com/landonb/home-fries
# Summary: Cyclopath bash startup script.
# License: GPLv3

# Initialize a few things depending on whether the machine is
# a remote development machine or a machine on the CS network.
# Note: BASH_SOURCE stores the name of the file being sourced
# (whereas $0 stores the name of the executable, e.g., 'bash').
HARD_PATH=$(dirname -- $(readlink -f -- "${BASH_SOURCE}"))
source ${HARD_PATH}/bashrc.cyclopath.loc.home.sh
source ${HARD_PATH}/bashrc.cyclopath.loc.work.sh

source path_util.sh

# MAGIC_NUMBER/SYNC_ME: 'minnesota' is our default psql schema.
# You can still access other schemas in the database (read: the
# old Denver/Colorado instance), but it's a better idea to use
# a separate database entirely; using multiple schemas is more
# of a hassle than using multiple databases. Unfortunately, it
# was implemented as a hack so that multiple instances could
# share the same user tables, rather than breaking the user
# tables out into their own db.
export INSTANCE=minnesota

# DEVs: Set LOAD_PYTHONPATH=true to add to PYTHONPATH.
# FIXME: This is disabled so as not to conflict with other projects...
#        Ideally, Cyclopath would run in a chroot and then you could
#        have this operation performed only in the chroot.
LOAD_PYTHONPATH=false
#LOAD_PYTHONPATH=true

# Create the pyserver dump directory and make sure www-data/apache can write to
# it. NOTE This directory should match what's in the source, in pyserver/CONFIG
# 2014.01.22: This code is probably obsolete:
#             We write to /ccp/var/log/pyserver_dumps nowadays.
if ! [[ -e /tmp/pyserver_dumps ]]; then
  mkdir -p /tmp/pyserver_dumps
fi
filemode=$(stat --format=%a /tmp/pyserver_dumps/)
if [[ ${filemode} != '2777' ]]; then
  chmod 2777 /tmp/pyserver_dumps
fi

# Cyclopath directory structure

export CCP_DIR=/ccp
# Path to Cyclopath development tools checkout.
export CCP_DEV_BIN=/ccp/bin
# Path to local working copies of Cyclopath source.
export CCP_DEV_DIR=/ccp/dev
# Path to developer thingies, like the nightly database snapshots.
export CCP_ETC_DIR=/ccp/etc
# FIXME Need a better name
export CS_PATHBACKUP=$CCP_DEV_DIR/cp_dubs.back
# Add the Flex build tools to PATH.
path_add_part "/ccp/opt/flex/bin"
# FIXME: echoing a warning breaks unison, which expects
#        a clean response on ssh or whatever it uses.
#else
#  echo "WARNING: missing: /ccp/opt/flex/bin"

# Cyclopath shortcuts

# FIXME /tmp/pyserver_dumps should be $... and maybe should be mkdir dirred
## Shortcut to the pyserver crash dump
alias xx='less /tmp/pyserver_dumps/dump.EXCEPT'

# Crontab tricks

# Cheap daily.sh cronjob-detector
#alias psgd='ps aux | grep daily'
# NOTE: We need double quotes; if we singly-quote, spanning the alias across
#       multiple lines doesn't work.
# NOTE: Do the exclusion (-v) first so that grep highlights the output.
# NOTE: This should exclude grep, very restrictively: '0:00 grep --color -e'
alias psgd="\
   ps aux \
    | grep -v \
      -e '0:00 grep --color -e' \
      -e 'services/alleyoop.py' \
      -e 'services/routed.py' \
      -e 'services/mr_do.py' \
    | grep \
      -e '/ccp/bin/ccpdev' \
      -e '/ccp/dev/[-_a-zA-Z0-9]\+/' \
      -e './tilecache_update.py' \
      -e './tilecache_seed.py' \
   "
alias psrd="\
   ps aux \
    | grep \
      -e 'services/alleyoop.py' \
      -e 'services/routed.py' \
      -e 'services/mr_do.py' \
      -e 'START \+TIME \+COMMAND'
   "
# See also:
#  pstree -p ${CS_USERNAME}
# but this is a less simple grep, e.g.,
#   $ pstree -p ${USER}
#   sh(14630)───publish_ccpv1-v(14635)───db_load.sh(14843)───perl(14850)───psql(16681)
#   schema-upgrade.(18635)───sh(30421)───psql(30423)

ctwait () {
  echo -n "Waiting for daily cronjob to start..."
  still_waiting=1
  while [[ $still_waiting -ne 0 ]]; do
    # We cannot check for the process with just one command because our grep
    # would spoil the search results (sounds like quantum physics, where the
    # observer changes the experiment).
    matching_tasks=`ps aux | grep daily`
    # We could restrict to just this machine's daily script but we should let
    # ourselves run other machines' scripts, since they're all pretty similar.
    # grep_results=`echo $matching_tasks | grep "/ccp/bin/ccpdev/daily/daily.${HOSTNAME}"`
    grep_results=`echo $matching_tasks | grep "/ccp/bin/ccpdev/daily/daily."`
    if [[ -n "$grep_results" ]]; then
      still_wait  ing=0
    else
      # The default for date is, e.g., Mon Apr  2 12:20:00 CDT 2012
      #second_hand=`date | sed 's/^\w\{3\} \w\{3\}  \?[0-9][0-9]\? [0-9]\{2\}:[0-9]\{2\}:\([0-9]\{2\}\) .*/\1/'`
      # But this is much simpler,
      second_hand=`date +%S`
      #echo -n "."
      echo -n "${second_hand}."
      sleep 1
    fi
  done
  echo " ok."
  # Open the user's crontab for editing.
  crontab -e -u $USER
}

## Watch log files

### Watch the Client logs
#
# 2012.10.17: Convert logc to a command so we can execute it on bash startup.
#  alias logc='tail -F ~/.macromedia/Flash_Player/Logs/flashlog.txt'
function logc () {
  tail -F ~/.macromedia/Flash_Player/Logs/flashlog.txt
}
#
# Note the echo because we're using backticks and not single quotes
# (the echo really isn't part of the alias).
# EXPLAIN: I can't remember why the latter and not the next:
#alias flog='fa ~/.macromedia/Flash_Player/Logs/flashlog.txt'
alias flog=`echo fa ~/.macromedia/Flash_Player/Logs/flashlog.txt`

### Watch the Server logs
#
logs () {
  ${DUBS_TRACE} && echo "logs"
	tail_cmd="sudo tail -F"
	# If you want to confirm what's being tailed, try:
	#   sudo tail -F -n 0
	if [[ -e /var/log/apache2/access.log ]]; then
		tail_cmd="
			$tail_cmd
			/var/log/apache2/access.log
			/var/log/apache2/error.log"
	fi
	if [[ -e /var/log/nginx/access.log ]]; then
		tail_cmd="
			$tail_cmd
			/var/log/nginx/access.log
			/var/log/nginx/error.log"
	fi
	if [[ $(ls /var/log/postgresql/postgresql-*-main.log 2> /dev/null) \
			|| $? -eq 0 ]]; then
		tail_cmd="
			$tail_cmd
			/var/log/postgresql/postgresql-*-main.log"
	fi
  if [[ -e /ccp/var/log/postgresql/postgresql-Mon.log ]]; then
    # SYNC_ME: Search postgresql-%a.log
    tail_cmd="
      $tail_cmd
        /ccp/var/log/postgresql/postgresql-Mon.log
        /ccp/var/log/postgresql/postgresql-Tue.log
        /ccp/var/log/postgresql/postgresql-Wed.log
        /ccp/var/log/postgresql/postgresql-Thu.log
        /ccp/var/log/postgresql/postgresql-Fri.log
        /ccp/var/log/postgresql/postgresql-Sat.log
        /ccp/var/log/postgresql/postgresql-Sun.log"
  fi
  if [[ -e /ccp/var/log/pgbouncer/pgbouncer.log ]]; then
    tail_cmd="
      $tail_cmd
      /ccp/var/log/pgbouncer/pgbouncer.log"
  fi
  # Special Cyclopath locations.
	if [[ -e /ccp/var/log/postgresql/postgresql.log ]]; then
		tail_cmd="
			$tail_cmd
      /ccp/var/log/postgresql/postgresql.log"
	fi
  LOG_PREFIX=/ccp/var/log/pyserver/
  for instance_name in "colorado" "minnesota" "no_instance"; do
    tail_cmd="
      $tail_cmd
      ${LOG_PREFIX}${instance_name}-apache.log
      ${LOG_PREFIX}${instance_name}-misc.log
      ${LOG_PREFIX}${instance_name}-mr_do.log
      ${LOG_PREFIX}${instance_name}-routed.log
      ${LOG_PREFIX}${instance_name}-spark.log
      ${LOG_PREFIX}${instance_name}-tilecache.log"
  done
  eval $tail_cmd
}

## Control and Kill Processes

### Kill all processes: Flex wrapper, fcsh
killfc () {
  # Kill the following:
  #   /bin/sh /ccp/opt/flex/bin/fcsh
  #   java ... -jar /ccp/opt/flex/bin/../lib/fcsh.jar
  #   /usr/bin/python ./fcsh-wrap ...

  # 2013.06.11: This used to pipe from ps to the kill, but we didn't grep out
  # the grep from ps, so if fcsh isn't running, kill gets the process id of the
  # grep command, which is already dead by the time kill tries to kill it. But
  # if we grep out the grep, kill gets called with no arguments.
  #
  #  $ ps aux \
  #     | grep -e bin/fcsh$ -e lib/fcsh.jar$ -e "python ./fcsh-wrap" \
  #     | awk '{print $2}' \
  #     | xargs sudo kill -s 9
  #  kill: No such process
  #
  # and
  #
  #  $ ps aux \
  #     | grep -e bin/fcsh$ -e lib/fcsh.jar$ -e "python ./fcsh-wrap" \
  #     | grep -v grep \
  #     | awk '{print $2}' \
  #     | xargs sudo kill -s 9
  #  Usage:
  #    kill pid ...              Send SIGTERM to every process listed.
  #    ...
  #
  # So a more deliberate approach is necessary.

  pids=$(ps aux \
         | grep -e bin/fcsh$ -e lib/fcsh.jar$ -e "python ./fcsh-wrap" \
         | grep -v grep \
         | awk '{print $2}')
  for pid in $pids; do
    ${DUBS_TRACE} && echo "killfc: $pid"
     sudo kill -s 9 $pid
  done
  return 0
}

# 2013.08.21: Make sure you're using flashclient/Makefile-new and
#             flashclient/fcsh-wrap-new to use the remake command.
#             Otherwise, just `killfc; make clean; make; make; etc.`
remake () {
   killfc
   sleep 1
   make clean
   make one
   # The linux flex compiler shell (fcsh) generally fails on
   # the first few make attempts before finally succeeding.
   max_tries=6
   while [[ $max_tries -gt 0 ]]; do
      # Running grep works, but it outputs, so rather than redirect...
      #   grep Error /tmp/flashclient_make
      #     if [[ $? == 0 ]]; then ... fi
      if [[ "`cat /tmp/flashclient_make | grep Error`" ]]; then
         make again
         max_tries=$((max_tries-1))
      else
         echo "Success after $((7-max_tries)) tries"
         max_tries=-1
      fi
   done
   if [[ "`cat /tmp/flashclient_make | grep Error`" ]]; then
      echo "I give up\!"
   fi
   # Get the ccp working directory, i.e., ../..
   working_dir=$(basename -- $(dirname -- "${PWD}"))
   fixperms --public ../../${working_dir}/
   # FIXME: Add wincopy behavior (from flashclient/Makefile)
} # re

### Kill all processes: Flex wrapper, fcsh
is_fcsg_running () {
  # Kill the following:
  #   /bin/sh /ccp/opt/flex/bin/fcsh
  #   java ... -jar /ccp/opt/flex/bin/../lib/fcsh.jar
  #   /usr/bin/python ./fcsh-wrap ...
  # 2015.01.25: Hahaha, I must not use this cmd: was missing: grep -v grep.
  if [[ "`ps aux \
          | grep -e bin/fcsh$ -e lib/fcsh.jar$ -e "python ./fcsh-wrap" \
          | grep -v grep \
          | awk '{print $2}'`" ]]; then
    is_running=1
  else
    is_running=0
  fi
  return ${is_running}
}

### Kill all processes: Routed
killrd () {
  # If we grep just routed, it kills our tail command.
  ## NO: ps aux | grep routed | awk '{print $2}' | xargs sudo kill -s 9
  #ps aux | grep "\-\-routed_pers" | awk '{print $2}' | xargs sudo kill -s 9
  ## ?: ps aux | grep routedctl | awk '{print $2}' | xargs sudo kill -s 9
  killsomething "\-\-routed_pers"
  # FIXME: Read from CONFIG, then truncate routed_ports
  #psql -U postgres -d ccpv2 -c "TRUNCATE minnesota.routed_ports;"
  return 0
}

killrd2 () {
  ${DUBS_TRACE} && echo "killrd2"
  ps aux | grep routed_pers=v2 | awk '{print $2}' | xargs sudo kill -s 9
  return 0
}

### Kill all processes: Apache
killre () {
  ${DUBS_TRACE} && echo "killre"
  ps aux | grep /usr/sbin/apache2 | awk '{print $2}' | xargs sudo kill -s 9
  return 0
}

## Interact with the database

### Login to the Database
cpdb () {
  if [[ -z "$1" ]]; then
    psql -U cycling cycling
  else
    psql -U cycling cycling$1
  fi
}

### Reload the database from the nightly build
#dbload () {
#  if [[ -z "$1" ]]; then
#    $cp/scripts/db_load.sh $cpu/prod_nightly_lite.dump cycling
#  else
#    $cp/scripts/db_load.sh $cpu/prod_nightly_lite.dump cycling$1
#  fi
#}
#dbload-all () {
#  if [[ -z "$1" ]]; then
#    $cp/scripts/db_load.sh $cpu/prod_nightly.dump cycling
#  else
#    $cp/scripts/db_load.sh $cpu/prod_nightly.dump cycling$1
#  fi
#}

# SYNC_ME: This same list is C.f. other cron scripts and bash scripts.
# MAYBE: If we want to exclude the non-apache tables, we'd have to recreate
#        them. 2012.09.28: Excluding them only saves a few 10s of MBs.
#        SOLUTION: Make SQL script to recreate...
CCP_LITE_IGNORE_TABLES="
  """*.apache_event"""
  """*.apache_event_session"""
  """*.auth_fail_event"""
  """*.ban"""
  """*.log_event"""
  """*.log_event_kvp"""
  "
# Additional possibilities:
# --exclude-table '''*.user_preference_event''' \
# --exclude-table '''*.byway_rating_event''' \
# --exclude-table '''*.tag_preference_event''' \
# --exclude-table '''*.route''' \
# --exclude-table '''*.route_step''' \
# --exclude-table '''*.route_waypoint''' \
# etc.
#
CCP_LITE_INCLUDE_TABLES=""
for table in ${CCP_LITE_IGNORE_TABLES}; do
  # NOTE: Single quotes don't work here: bash doesn't interpolate singlie-'s.
  CCP_LITE_INCLUDE_TABLES="$CCP_LITE_INCLUDE_TABLES --table $table "
done
#
CCP_LITE_EXCLUDE_TABLES=""
for table in ${CCP_LITE_IGNORE_TABLES}; do
  # NOTE: Single quotes don't work here: bash doesn't interpolate singlie-'s.
  CCP_LITE_EXCLUDE_TABLES="$CCP_LITE_EXCLUDE_TABLES --exclude-table $table "
done

### Create/Restore database snapshot
dbbak () {
  # FIXME: Should these not just be named lite.dump but either include the
  # database name or the date?
  if [[ -z "$1" ]]; then
    pg_dump -U cycling cycling -Fc ${CCP_LITE_EXCLUDE_TABLES} \
      > /ccp/var/dbdumps/lite.dump
  else
    pg_dump -U cycling cycling$1 -Fc ${CCP_LITE_EXCLUDE_TABLES} \
      > /ccp/var/dbdumps/lite.dump
  fi
}
# FIXME Rename fcn.
dbbak-load () {
  if [[ -z "$1" ]]; then
    $cp/scripts/db_load.sh /ccp/var/dbdumps/lite.dump cycling
  else
    $cp/scripts/db_load.sh /ccp/var/dbdumps/lite.dump cycling$1
  fi
}

## Manage Source Code Working Directories

### Re-link the working directory shortcut
cpln () {
  if [[ -z "$1" ]]; then
    echo Please specify the Bug \# of the branch to activate
    echo Usage: cpln bugnum
    return 0
  fi
  dest=$1
  if [[ ! -d "$CCP_DEV_DIR/$dest" ]]; then
    # Try cp_ prefix.
    dest=cp_$1
    if [[ ! -d "$CCP_DEV_DIR/$dest" ]]; then
      echo The branch for Bug $1 does not exist
      return 0
    fi
  fi
  # Backup and save the existing link's branch's .vimprojects.
  mv -f $cp/.vimprojects $cp/.vimprojects-bak
  cp ~/.vimprojects $cp/.vimprojects
  # Remove and replace the link(s).
  /bin/rm -f $cp
  ln -s $CCP_DEV_DIR/$dest $cp
  #/bin/rm -f $CCP_DEV_DIR/cp_cron
  #ln -s $CCP_DEV_DIR/$dest $CCP_DEV_DIR/cp_cron
  /bin/rm -f $cpw
  if [[ -d "$CCP_DEV_DIR/$dest_WORKING" ]]; then
    ln -s $CCP_DEV_DIR/$dest_WORKING $cpw
  fi
  # Vim project file
  if [[ -f "$CCP_DEV_DIR/$dest/.vimprojects" ]]; then
    mv -f ~/.vimprojects ~/.vimprojects-bak
    cp $CCP_DEV_DIR/$dest/.vimprojects ~/.vimprojects
  fi
}

# ## Copy Cyclopath config files to the current working directory.
#
# cpcfg () {
#   cp -f $CCP_ETC_DIR/cp_confs/CONFIG \
#                  $cp/pyserver/CONFIG
#   cp -f $CCP_ETC_DIR/cp_confs/Conf_Instance.as \
#                  $cp/flashclient/Conf_Instance.as
#   cp -f $CCP_ETC_DIR/cp_confs/database.map \
#                  $cp/mapserver/database.map
#   cp -f $CCP_ETC_DIR/cp_confs/check_cache_now.sh \
#                  $cp/mapserver/check_cache_now.sh
#   cp -f $CCP_ETC_DIR/cp_confs/kill_cache_check.sh \
#                  $cp/mapserver/kill_cache_check.sh
# }
#
# cpCFG () {
#   # FIXME: Make backups of existing
#   cp -f $cp/pyserver/CONFIG \
#         $CCP_ETC_DIR/cp_confs/CONFIG
#   cp -f $cp/flashclient/Conf_Instance.as \
#         $CCP_ETC_DIR/cp_confs/Conf_Instance.as
#   cp -f $cp/mapserver/database.map \
#         $CCP_ETC_DIR/cp_confs/database.map
#   cp -f $cp/mapserver/check_cache_now.sh \
#         $CCP_ETC_DIR/cp_confs/check_cache_now.sh
#   cp -f $cp/mapserver/kill_cache_check.sh \
#         $CCP_ETC_DIR/cp_confs/kill_cache_check.sh
# }

cp_basedir_check () {
  # We could check for existance of one or more of the config files, like
  # pyserver/CONFIG and/or flashclient/Conf_Instance.as. But we check for
  # pyserver/VERSION.py, which is created when you make flashclient. So
  # this verifies that the config files exist and that the client may have
  # been made (though I suppose we could just as easily check for main.swf).
  is_cp_basedir=1
  if [[ $2 == "--strict" ]]; then
    if [[ -e "$1/pyserver/VERSION.py" ]]; then
      # Note the Bash is weird and 0 is true when used with if. I mean,
      # a nonzero return indicates an error message (in $?).
      is_cp_basedir=0
    fi
  else
    if [[ -d "$1/pyserver" && -d "$1/flashclient" ]]; then
      is_cp_basedir=0
    fi
  fi
  return $is_cp_basedir
}

cp_basedir () {
  VERBOSE=false
  $VERBOSE && echoerr "cp_basedir: 1: $1 / 2: $2"
  cp_dir=$1
  if [[ -z "$cp_dir" ]]; then
    cp_dir=`pwd`
    $VERBOSE && echoerr "cp_basedir: pwd: $cp_dir"
  else
    cp_dir=$(readlink -f -- "${cp_dir}")
    $VERBOSE && echoerr "cp_basedir: resolved path: $cp_dir"
  fi
  if [[ ! -d "$cp_dir" ]]; then
    $VERBOSE && echoerr "cp_basedir: not a directory: $cp_dir"
    cp_dir=""
  else
    $VERBOSE && echoerr "cp_basedir: starting on: $cp_dir"
    while [[ $cp_dir != '/' ]] ; do
      # NOTE: $2 might be --strict
      if cp_basedir_check $cp_dir $2; then
        $VERBOSE && echoerr "cp_basedir: cp_basedir_check'd: $cp_dir"
        break
      else
        cp_dir=`dirname $cp_dir`
        $VERBOSE && echoerr "cp_basedir: dirname'd: $cp_dir"
      fi
    done
    if [[ $cp_dir == '/' ]] ; then
      $VERBOSE && echoerr "cp_basedir: reached parent: $cp_dir"
      cp_dir=""
    fi
  fi
  $VERBOSE && echoerr "cp_basedir: final cp_dir: $cp_dir"
  echo $cp_dir
}

# Copy, Save and Restore Cyclopath config files to any directory.
cpconf () {
  VERBOSE=false
  $VERBOSE && echoerr "cpconf: \$1: $1"
  if [[ -z "$1" ]]; then
    echo "Please specify a command and maybe one or two directories."
    echo "Usage: cpconf {copy|save|restore|diff} [dir_1 [dir_2]]"
    return 1
  fi
  cmd_action=$1
  dir_1=$2
  dir_2=$3
  $VERBOSE && echoerr "cmd_action: $cmd_action"
  $VERBOSE && echoerr "dir_1: $dir_1"
  $VERBOSE && echoerr "dir_2: $dir_2"
  # MAYBE: $VERBOSE && $VERBOSE && echoerr ...
  if [[ "$cmd_action" == "copy" ]]; then
    $VERBOSE && echoerr "dir_1: $dir_1"
    cp_dir_src=`cp_basedir $dir_1`
    $VERBOSE && echoerr "cp_dir_src: $cp_dir_src"
    $VERBOSE && echoerr "dir_2: $dir_2"
    cp_dir_dst=`cp_basedir $dir_2`
    $VERBOSE && echoerr "cp_dir_dst: $cp_dir_dst"
    if [[ ! -d $cp_dir_src ]]; then
      echoerr "Not a Cyclopath dev directory: $dir_1"
      return 1
    fi
    if [[ ! -d $cp_dir_dst ]]; then
      echoerr "Not a Cyclopath dev directory: $dir_2"
      return 1
    fi
    $VERBOSE && echoerr "Copying from $dir_1 to $dir_2"
    /bin/cp -f $cp_dir_src/pyserver/CONFIG \
               $cp_dir_dst/pyserver/CONFIG
    /bin/cp -f $cp_dir_src/flashclient/Conf_Instance.as \
               $cp_dir_dst/flashclient/Conf_Instance.as
    # FIXME: See mapserver/make_mapfile.py and gen_tilecache_cfg.py.
    #        This is the old code:
    /bin/cp -f $cp_dir_src/mapserver/database.map \
               $cp_dir_dst/mapserver/database.map
    if [[ -e $cp_dir_src/mapserver/tilecache.cfg ]]; then
      /bin/cp -f $cp_dir_src/mapserver/tilecache.cfg \
                 $cp_dir_dst/mapserver/tilecache.cfg
    fi
    # 2013.04.24: check_cache_now.sh is new.
    /bin/cp -f $cp_dir_src/mapserver/check_cache_now.sh \
               $cp_dir_dst/mapserver/check_cache_now.sh
    /bin/cp -f $cp_dir_src/mapserver/kill_cache_check.sh \
               $cp_dir_dst/mapserver/kill_cache_check.sh
    # 2013.04.01: Also copy the Makefile, which varies now for DEVs.
    # 2013.12.28: Makefile is now a symlink to Makefile-new.
    #  /bin/cp -f $cp_dir_src/flashclient/Makefile \
    #             $cp_dir_dst/flashclient/Makefile
    # 2013.04.24: Why not copy .vimprojects, too.
    if [[ -e $cp_dir_src/.vimprojects ]]; then
      /bin/cp -f $cp_dir_src/.vimprojects \
                 $cp_dir_dst/.vimprojects
    fi
    if [[ -e $cp_dir_src/log.txt ]]; then
      /bin/cp -f $cp_dir_src/log.txt \
                 $cp_dir_dst/log.txt
    fi
    # 2013.08.22: htdocs/reports/.htaccess has a local path in it.
    if [[ -e $cp_dir_src/htdocs/reports/.htaccess ]]; then
       /bin/cp -f $cp_dir_src/htdocs/reports/.htaccess \
                  $cp_dir_dst/htdocs/reports/.htaccess
    fi
    if [[ -e $cp_dir_src/htdocs/reports/.htpasswd ]]; then
       /bin/cp -f $cp_dir_src/htdocs/reports/.htpasswd \
                  $cp_dir_dst/htdocs/reports/.htpasswd
    fi
    # WANTED: Do an svn status and find other missing items to copy.
  elif [[ "$cmd_action" == "diff" ]]; then
    cp_dir_src=`cp_basedir $dir_1`
    cp_dir_dst=`cp_basedir $dir_2`
    if [[ ! -d $cp_dir_src ]]; then
      echoerr "Not a Cyclopath dev directory: $dir_1"
      return 1
    fi
    if [[ ! -d $cp_dir_dst ]]; then
      echoerr "Not a Cyclopath dev directory: $dir_2"
      return 1
    fi
    $VERBOSE && echoerr "Diffing $dir_1 vs. $dir_2"
    diff $cp_dir_src/pyserver/CONFIG \
         $cp_dir_dst/pyserver/CONFIG
    diff $cp_dir_src/flashclient/Conf_Instance.as \
         $cp_dir_dst/flashclient/Conf_Instance.as
    #
    diff $cp_dir_src/mapserver/database.map \
         $cp_dir_dst/mapserver/database.map
    #
    diff $cp_dir_src/mapserver/check_cache_now.sh \
         $cp_dir_dst/mapserver/check_cache_now.sh
    diff $cp_dir_src/mapserver/kill_cache_check.sh \
         $cp_dir_dst/mapserver/kill_cache_check.sh
    #
    # 2013.12.28: Makefile is now a symlink to Makefile-new.
    #  diff $cp_dir_src/flashclient/Makefile \
    #       $cp_dir_dst/flashclient/Makefile
    #
    diff $cp_dir_src/htdocs/reports/.htaccess \
         $cp_dir_dst/htdocs/reports/.htaccess
    diff $cp_dir_src/htdocs/reports/.htpasswd \
         $cp_dir_dst/htdocs/reports/.htpasswd
  else
    strict=""
    if [[ "$cmd_action" == "save" ]]; then
      strict="--strict"
      if [[ ! -d "$dir_1" ]]; then
        dir_1=$(pwd)
      fi
    elif [[ "$cmd_action" == "restore" ]]; then
      if [[ ! -d "$dir_1" ]]; then
        dir_1=$cp
      fi
    else
      echoerr "Unknown command: $cmd_action"
      return 1
    fi
    cp_dir_src=`cp_basedir $dir_1 $strict`
    if [[ ! -d $cp_dir_src ]]; then
      echoerr "Not a Cyclopath dev directory: $dir_1"
      return 1
    fi
    if [[ "$cmd_action" == "save" ]]; then
      $VERBOSE && echoerr "Saving $cp_dir_src"
      /bin/cp -f $cp_dir_src/pyserver/CONFIG ./CONFIG
      /bin/cp -f $cp_dir_src/flashclient/Conf_Instance.as ./Conf_Instance.as
      /bin/cp -f $cp_dir_src/mapserver/database.map ./database.map
      # Note that tilecache.cfg is now generated by mapserver/make_mapfile.py and
      # gen_tilecache_cfg.py.
      if [[ -e $cp_dir_src/mapserver/tilecache.cfg ]]; then
        /bin/cp -f $cp_dir_src/mapserver/tilecache.cfg ./tilecache.cfg
      fi
      /bin/cp -f $cp_dir_src/mapserver/check_cache_now.sh \
                 ./check_cache_now.sh
      /bin/cp -f $cp_dir_src/mapserver/kill_cache_check.sh \
                 ./kill_cache_check.sh
      # 2013.04.01: Also copy the Makefile, which varies now for DEVs.
      # 2013.12.28: Makefile is now a symlink to Makefile-new.
      #  /bin/cp -f $cp_dir_src/flashclient/Makefile ./Makefile
      # 2013.08.22: htdocs/reports/.htaccess has a local path in it.
      if [[ -e $cp_dir_src/htdocs/reports/.htaccess ]]; then
         /bin/cp -f $cp_dir_src/htdocs/reports/.htaccess ./.htaccess
      fi
      if [[ -e $cp_dir_src/htdocs/reports/.htpasswd ]]; then
         /bin/cp -f $cp_dir_src/htdocs/reports/.htpasswd ./.htpasswd
      fi
    elif [[ "$cmd_action" == "restore" ]]; then
      $VERBOSE && echoerr "Restoring $cp_dir_src"
      /bin/cp -f ./CONFIG $cp_dir_src/pyserver/CONFIG
      /bin/cp -f ./Conf_Instance.as $cp_dir_src/flashclient/Conf_Instance.as
      /bin/cp -f ./database.map $cp_dir_src/mapserver/database.map
      if [[ -e ./tilecache.cfg ]]; then
        /bin/cp -f ./tilecache.cfg $cp_dir_src/mapserver/tilecache.cfg
      fi
      /bin/cp -f ./check_cache_now.sh \
                 $cp_dir_src/mapserver/check_cache_now.sh
      /bin/cp -f ./kill_cache_check.sh \
                 $cp_dir_src/mapserver/kill_cache_check.sh
      # 2013.04.01: Also copy the Makefile, which varies now for DEVs.
      # 2013.12.28: Makefile is now a symlink to Makefile-new.
      #  /bin/cp -f ./Makefile $cp_dir_src/flashclient/Makefile
      # 2013.08.22: htdocs/reports/.htaccess has a local path in it.
      if [[ -e ./.htaccess ]]; then
         /bin/cp -f ./.htaccess $cp_dir_src/htdocs/reports/.htaccess
      fi
      if [[ -e ./.htpasswd ]]; then
         /bin/cp -f ./.htpasswd $cp_dir_src/htdocs/reports/.htpasswd
      fi
    fi
  fi
}

## Build shortcuts

alias tua='\
  ${DUBS_TRACE} && echo "tua" ; \
  pushd $cp/pyserver ; \
  sudo -u $httpd_user INSTANCE=minnesota ./tilecache_update.py -a ; \
  popd'
alias tun='\
  ${DUBS_TRACE} && echo "tun" ; \
  pushd $cp/pyserver ; \
  sudo -u $httpd_user INSTANCE=minnesota ./tilecache_update.py -n ; \
  popd'

# Run routed (from $cp/pyserver)
#alias rd='pushd $cp/pyserver ; sudo -u $httpd_user INSTANCE=minnesota ./routedctl ; popd'
# Clean restart
alias gocp='pushd $cp ; ./fixperms.sh ; killfc ; cd $cp/flashclient ; make clean ; make ; cd $cp ; ./fixperms.sh ; re ; killfc ; popd'
alias golite='pushd $cp/flashclient ; make ; cd $cp ; ./fixperms.sh ; popd'
alias golitr='killfc ; pushd $cp/flashclient ; make ; cd $cp ; ./fixperms.sh ; popd ; re ; killfc'
#alias golite1='pushd $cp/flashclient ; touch Item_Versioned.as Link_Value.as Geofeature.as Attachment.as items/* Detail* commands/* ; make ; cd $cp ; ./fixperms.sh ; popd'

# 2011.03.23: Created cpci
# 2012.06.26: Noting that I never use cpci
alias cpci='svn ci -F /ccp/dev/cp/checkin.txt'

# 2011.12.09
# Note that the trailing slash is required.
alias fixcp='fixperms --public $cp/'
alias fixcdc='fixperms --public /ccp/bin/ccpdev/'
alias fixdev='fixperms --public /ccp/dev/'
alias fixcps='fixperms --public /ccp/dev/cp/ /ccp/dev/cp_cron/ /ccp/dev/cycloplan_live/ /ccp/dev/cycloplan_test/'
alias fixcpp='fixperms --public /ccp/dev/cycloplan_sib1/ /ccp/dev/cycloplan_sib2/'
alias putcps='cpput cp -r ${CS_HOSTNAME}'
fixcpf () {
   # Assumes you're one-deep in Cyclopath folder, e.g., in flashclient/.
   # MAYBE: See Cyclopath source for fcn. to find source folder base.
   working_dir=$(basename -- $(dirname -- "$PWD"))
   fixperms --public ../../${working_dir}/
}

# Development directory shortcuts

# FIXME Should these be aliases? Like, 
# alias cp-='pushd $CCP_DEV_DIR/cp'
# FIXME: 2012.06.27: Most of these aren't used, or at least the convention is
# strong enough that I should just type /ccp/blah and not worry about managing
# all of these variables...
export ccp=$CCP_DIR
export cp=$CCP_DEV_DIR/cp
export cpw=$CCP_DEV_DIR/cpw
export cpc=$CCP_ETC_DIR/cp_confs

# 2012.10.17: Shortcuts for [lb]'s standard working and checkin dirs.
export cp1=${CCP_DEV_DIR}/ccpv1_trunk
export cp2=${CCP_DEV_DIR}/ccpv2_trunk
export cp3=${CCP_DEV_DIR}/ccpv3_trunk
#
export vp1=${CCP_DEV_DIR}/cp_trunk_v1
export vp2=${CCP_DEV_DIR}/cp_trunk_v2
export vp3=${CCP_DEV_DIR}/cp_trunk_v3

# Alias directory-changing shortcuts
#alias cdd='pushd ${CCP_DEV_DIR} > /dev/null'
# FIXME: Pick an alternative:
alias cpd='pushd ${CCP_DEV_DIR} > /dev/null'
#alias ccd='pushd ${CCP_DEV_DIR} > /dev/null'

# Shortcuts for [lb]'s standard working and checkin dirs.
#
# These are the working directories.
alias cd1='pushd ${CCP_DEV_DIR}/ccpv1_trunk > /dev/null'
alias cd2='pushd ${CCP_DEV_DIR}/ccpv2_trunk > /dev/null'
alias cd3='pushd ${CCP_DEV_DIR}/ccpv3_trunk > /dev/null'
#
# These are the checkin directories.
# NOTE: These are named similarly to the working directories...
alias vd1='pushd ${CCP_DEV_DIR}/cp_trunk_v1 > /dev/null'
alias vd2='pushd ${CCP_DEV_DIR}/cp_trunk_v2 > /dev/null'
alias vd3='pushd ${CCP_DEV_DIR}/cp_trunk_v3 > /dev/null'

# Alias to, e.g., /ccp/bin/ccpdev
##alias cdc='cd ${CCP_DIR}/bin/ccpdev'
#alias cdc='pushd ${CCP_DIR}/bin/ccpdev > /dev/null'
alias cpc='pushd ${CCP_DIR}/bin/ccpdev > /dev/null'
#alias cpb='pushd ${CCP_DIR}/bin/ccpdev > /dev/null'

# Alias to, e.g., /ccp/var/log/daily
#alias cdl='cd /ccp/var/log'
alias cdl='pushd /ccp/var/log > /dev/null'
# Alias to, e.g., /ccp/var/log/daily
#alias cdld='cd /ccp/var/log/daily'
alias cdld='pushd /ccp/var/log/daily > /dev/null'
# Alias to, e.g., /ccp/var/log/pyserver
# FIXME: Need a three-char name; also, not used very often...
#alias cdlp='cd /ccp/var/log/pyserver'
alias cdlp='pushd /ccp/var/log/pyserver > /dev/null'
alias cdpd='pushd /ccp/var/log/pyserver_dumps > /dev/null'

alias cde='pushd $CCP_ETC_DIR/cp_confs > /dev/null'
alias cdt='pushd /ccp/var/tilecache-cache > /dev/null'
alias cddb='pushd /ccp/var/dbdumps > /dev/null'

# NOTE: In Ubuntu 11.04, /ccp/opt/gdal/lib/python2.7 does not exist
#       gdal is in /ccp/opt/usr/lib/python2.7/site-packages instead
#       (which is where it belongs, anyway).
# 2012.04.12: On runic, the new production server, installing gdal I get
#               TEST FAILED: /ccp/opt/usr/lib/python2.6/site-packages 
#                            does NOT support .pth files
#             Which is because PYTHONPATH is bad
#               $ echo $PYTHONPATH
#               /ccp/opt/usr/lib/python:/ccp/opt/usr/lib//site-packages:
#                 /ccp/opt/gdal/lib//site-packages:
#             Which is because the bashrc scripts *do* have a particular load
#             order... 
#               $ echo $PYTHONVERS2
#               python2.6
# MAYBE: See /ccp/dev/cp/scripts/util/bash_base.sh: ccp_python_path does extra
#        magic: "Oddly, if we don't include the GDAL path,
#        'from osgeo import osr' fails under Ubuntu 11.04 (Python 2.7). Works
#        fine without under Ubuntu 10.04 (Python 2.6)."
# NOTE: Your scripts are run when you start X, so including $PYTHONPATH at the
# end just duplicates all the paths you already set up...
#export PYTHONPATH=$ccp/opt/usr/lib/python:$ccp/opt/usr/lib/$PYTHONVERS2/site-packages:$ccp/opt/gdal/lib/$PYTHONVERS2/site-packages:$PYTHONPATH

# 2015.03.26: FIXME: Figure out a better way to do this... chroot for Cyclopath??!
if $LOAD_PYTHONPATH; then
  export PYTHONPATH=$ccp/opt/usr/lib/python:$ccp/opt/usr/lib/$PYTHONVERS2/site-packages:$ccp/opt/gdal/lib/$PYTHONVERS2/site-packages:$ccp/dev/cp/pyserver/bin/winpdb
fi
unset LOAD_PYTHONPATH

if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
  # Ubuntu
  : 
elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
  # Fedora
  if [[ "`uname -m | grep x86_64`" ]]; then
    export PYTHONPATH=$PYTHONPATH:$ccp/opt/usr/lib64/python:$ccp/opt/usr/lib64/$PYTHONVERS2/site-packages
  fi
fi

# Subversion shortcuts

# SVN Server
if [[ -n $CS_MACHINESVN ]]; then
  export svnroot=svn+ssh://$CS_USERNAME@$CS_MACHINESVN$CS_SVNCYCLING
  export cptr=svn+ssh://$CS_USERNAME@$CS_MACHINESVN$CS_SVNCYCLING/public/trunk
  export cpbr=svn+ssh://$CS_USERNAME@$CS_MACHINESVN$CS_SVNCYCLING/br
fi

# Checkout a branch and make it the working directory
cpco () {
  if [[ -z "$1" ]]; then
    echo Please specify the Bug \# of the branch to checkout
    echo Usage: cpco [-w] bugnum
    echo "  -w: create 'working' checkout"
    return 0
  fi
  # NOTE I tried [ -n $2 ] but that didn't work...
  if [[ -z "$2" ]]; then
    BUGNUM=$1
    NEWDIR=cp_$1
  else
    if [[ "$1" = "-w" ]]; then
      BUGNUM=$2
      NEWDIR=cp_$2_WORKING
    else
      echo Unknown option "$1"
      return 0
    fi
  fi
  BRANCH=`svn list $cpbr | grep "$BUGNUM"`
  MATCHES=`echo $BRANCH | grep -c ' '`
  if [[ $MATCHES -gt 0 ]]; then
    echo More than one branch located: $BRANCH
    return 0
  fi
  if [[ -z "$BRANCH" ]]; then
    echo Branch not found for Bug $BUGNUM
    return 0
  fi
  # Make way for checkout dir
  if [[ -a "$CCP_DEV_DIR/$NEWDIR" ]]; then
    echo "Checkout dir. $NEWDIR already exists; moving"
    #mv $CCP_DEV_DIR/$NEWDIR $CCP_DEV_DIR/$NEWDIR-`date +%Y.%m.%d-%T`
    mv $CCP_DEV_DIR/$NEWDIR $CCP_DEV_DIR/$NEWDIR-`date +%Y.%m.%d.%H.%M.%S`
  fi
  # Checkout branch
  svn co $cpbr/$BRANCH $CCP_DEV_DIR/$NEWDIR
  # Make symlinks
  cpln $BUGNUM
  # Setup config files
  if [[ -z "$2" ]]; then
    cp $cpc/CONFIG $CCP_DEV_DIR/$NEWDIR/pyserver/
    cp $cpc/Conf_Instance.as $CCP_DEV_DIR/$NEWDIR/flashclient/
    cp $cpc/database.map $CCP_DEV_DIR/$NEWDIR/mapserver/
    # 2013.04.01: Also copy the Makefile, which varies now for DEVs.
    # 2013.12.28: Makefile is now a symlink to Makefile-new.
    #   cp $cpc/Makefile $CCP_DEV_DIR/$NEWDIR/flashclient/
  fi
}

# Checkout a branch, diff it against the trunk when it was branched, and view 
# it
diffbrr () {
  pushd $cp
  BRANCH=`svn info | grep URL: | sed "s/^.*\\/cyclingproject\\/br\\///g"`
  if [[ -z "$BRANCH" ]]; then
    echo Branch not found! \(In $cp\)
    popd
    return 0
  fi
  echo Found branch $BRANCH in `pwd`
  # This is hacky. But it seems easier than doing something less hacky.
  ORDINAL=1
  while [[ -a "diffbr-$ORDINAL.diff" ]]; do
    echo Found file diffbr-$ORDINAL.diff -- trying next ordinal
    ORDINAL=$((ORDINAL+1))
  done
  echo Ready to diff $BRANCH to diffbr-$ORDINAL.diff
  diffbr $BRANCH > diffbr-$ORDINAL.diff
  #fs diffbr-$ORDINAL.diff
  gvim --servername SAMPI --remote-silent diffbr-$ORDINAL.diff
  popd
}

# SYNC_ME: Next two fcns. are nearly identical.
# MAYBE: Rather than requiring user execute command from particular directory,
#        can you automatically manage the directories in /ccp/etc/cp_confs?

# Copy config files from server.
cpconf-get () {
  if [[ -z "$1" ]]; then
    echo Please specify the dev directory of the ccp confs to get.
    echo If the directory is on your remote development machine, use -r.
    echo Usage: cpconf-get {ccp-dev-dirname} [-r] {machine}
    return 0
  fi
  # FIXME: Bash has a built-in arg parser, right?
  if [[ -z "$2" ]]; then
    # Fetch from local. $1 is, e.g., "cp_1234" and maps to /ccp/dev/cp_1234.
    CCP_SRC_DIR=$CCP_DEV_DIR/$1
  else
    if [[ "$2" == "-r" ]]; then
      # Fetch from remote
      if [[ -z "$3" ]]; then
        CCP_SRC_DIR=$CS_USERNAME@$CS_MACHINEDEV:/ccp/dev/$1
      else
        CCP_SRC_DIR=$CS_USERNAME@$3.$CS_HOSTDOMAIN:/ccp/dev/$1
     fi
    else
      echo Unknown option "$2"
      return 0
    fi
  fi
  # Do it.
  echo "Fetching from ${CCP_SRC_DIR}"
  scp $CCP_SRC_DIR/pyserver/CONFIG                    .
  scp $CCP_SRC_DIR/flashclient/Conf_Instance.as       .
  scp $CCP_SRC_DIR/mapserver/database.map             .
  # This file is now generated: $CCP_SRC_DIR/mapserver/tilecache.cfg
  scp $CCP_SRC_DIR/mapserver/check_cache_now.sh       .
  scp $CCP_SRC_DIR/mapserver/kill_cache_check.sh      .
  # 2013.04.01: Also copy the Makefile, which varies now for DEVs.
  # 2013.12.28: Makefile is now a symlink to Makefile-new.
  #  scp $CCP_SRC_DIR/flashclient/Makefile            .
  # 2013.08.22: htdocs/reports/.htaccess has a local path in it.
  if [[ -e $CCP_SRC_DIR/htdocs/reports/.htaccess ]]; then
    scp $CCP_SRC_DIR/htdocs/reports/.htaccess         .
  fi
  if [[ -e $CCP_SRC_DIR/htdocs/reports/.htpasswd ]]; then
    scp $CCP_SRC_DIR/htdocs/reports/.htpasswd         .
  fi
}

# Copy config files to server.
cpconf-put () {
  if [[ -z "$1" ]]; then
    echo Please specify the dev directory of the ccp confs to get.
    echo If the directory is on your remote development machine, use -r.
    echo Usage: cpconf-put {ccp-dev-dirname} [-r] {machine}
    return 0
  fi
  # FIXME: Bash has a built-in arg parser, right?
  if [[ -z "$2" ]]; then
    # Copy to local
    CCP_SRC_DIR=$CCP_DEV_DIR/$1
  else
    if [[ "$2" == "-r" ]]; then
      # Copy to remote
      if [[ -z "$3" ]]; then
        CCP_SRC_DIR=$CS_USERNAME@$CS_MACHINEDEV:/ccp/dev/$1
      else
        CCP_SRC_DIR=$CS_USERNAME@$3.$CS_HOSTDOMAIN:/ccp/dev/$1
      fi
    else
      echo Unknown option "$2"
      return 0
    fi
  fi
  # Do it.
  echo "Copying to ${CCP_SRC_DIR}"
  scp CONFIG                  $CCP_SRC_DIR/pyserver/
  scp Conf_Instance.as        $CCP_SRC_DIR/flashclient/
  scp database.map            $CCP_SRC_DIR/mapserver/
  # tilecache.cfg is now generated by we still need this ccpv2_demo on runic.
  # This file is now generated: $CCP_SRC_DIR/mapserver/tilecache.cfg
  scp check_cache_now.sh      $CCP_SRC_DIR/mapserver/
  scp kill_cache_check.sh     $CCP_SRC_DIR/mapserver/
  # 2013.04.01: Also copy the Makefile, which varies now for DEVs.
  # 2013.12.28: Makefile is now a symlink to Makefile-new.
  #   scp Makefile                $CCP_SRC_DIR/flashclient/
  # 2013.08.22: htdocs/reports/.htaccess has a local path in it.
  if [[ -e .htaccess ]]; then
     scp .htaccess            $CCP_SRC_DIR/htdocs/reports/
  fi
  if [[ -e .htpasswd ]]; then
    scp .htpasswd             $CCP_SRC_DIR/htdocs/reports/
  fi
}

#####

export PYSERVER_HOME=$CCP_DEV_DIR/cp/pyserver

#####

# 2012.07.13: I find myself copying files from my dev. machine's working
# directory to the demo machine while testing (before checking in) so I 
# figured (am hoping) that this'll be a useful shortcut.

# E.g., 
# cd /ccp/dev/ccpv2_trunk
#   ccpcp runic pyserver/item/feat/node_endpoint.py pyserver/util_/geometry.py
# or simply, to copy files svn says are modified,
#   ccpcp runic 

# MAYBE: I'm not sure what fcn. name I like. svncp makes sense when you are not
# specifiying file names but are sending what's marked modifed in `svn status`.
function svncp () {
  ccpcp $*
}

function ccpcp () {
  if [[ "$1" == "" ]]; then
    echo "Please specify the relative path to copy remotely."
    echo "You may specify files or we'll send modified SVN files."
    echo "Usage: ccpcp {machine} [relative-file-paths]"
    return 0
  else
    REMOTE=$1
    DIR_CWD=`pwd`
    shift
    if [[ "$1" == "" ]]; then
      # Check that the current working directory is under revision control.
      # Note that `svn status` complains "svn: '.' is not a working copy" 
      # but its exit value is nonetheless 0, whereas `svn info` gives the 
      # same warning but also sets the exit value to 1.
      svn info > /dev/null 2>&1
      if [[ $? -ne 0 ]]; then
        echo "what svn says: svn: '.' is not a working copy"
      else
        # Copy files svn says are modified. We are not copying [A]dded files,
        # not do we handle [D]eleted or [?]Unknown files. (svn --help status 
        # also says there are [C]onflicted files, [I]gnored, [R]eplaced, and
        # [X], [?], [!], [~], but we just want [M]odified files.)
        #
        # Humpf. I tried to make awk and xargs work but they are so difficult
        # to use. This is the closest I got:
        #
        #   # MAGIC NUMBER: The $2nd column is the relative file path.
        #   svn status                        \
        #   | grep "^M"                       \
        #   | awk                             \
        #       -v REMOTE=$REMOTE             \
        #       -v DIR_CWD=$DIR_CWD           \
        #       '{printf "%s %s@%s.%s:%s/%s\n", 
        #         $2, 
        #         ENVIRON["CS_USERNAME"], 
        #         REMOTE, 
        #         ENVIRON["CS_HOSTDOMAIN"], 
        #         DIR_CWD, 
        #         $2}' # should be dirname... \
        #   | xargs                           \
        #   | xargs scp
        #
        # But then I couldn't figure out how to `dirname` the file path (since
        # scp wants to copy to a directory path, not to a file path) but xargs
        # is very simple and awk is very confusing, and using bash is much more
        # readable:
        for REL_PATH in `svn status | grep "^M" | sed "s/^M \+//"`; do
          scp \
            $REL_PATH \
            $CS_USERNAME@$REMOTE.$CS_HOSTDOMAIN:$DIR_CWD/`dirname $REL_PATH`
        done
      fi
    else
      for REL_PATH in $*; do
        scp $REL_PATH $CS_USERNAME@$REMOTE.$CS_HOSTDOMAIN:$DIR_CWD/$REL_PATH
      done
    fi
  fi
  return 0
}

# ***

# C.f. scripts/util/ccp_base.sh.
find_pyserver_uncle () {
  local script_dir_relative=$(dirname -- "$0")
  local here_we_are=$(dir_resolve ${script_dir_relative})

  while [[ ${here_we_are} != '/' ]]; do
    if [[ -e "${here_we_are}/pyserver/CONFIG" ]]; then
      # MAYBE: Really export? We were sourced, so maybe don't do this,
      #        so we don't clobber the user's working environment?
      export CCP_WORKING=${here_we_are}
      export PYSERVER_HOME=${CCP_WORKING}/pyserver
      break
    else
      # Keep looping:
      here_we_are=$(dir_resolve ${here_we_are}/..)
    fi
  done

  if [[ ${here_we_are} == '/' ]]; then
    echo "ERROR: Cannot suss out PYSERVER_HOME. Failing!"
    invoked_from_terminal
    if [[ $? -eq 0 ]]; then
      exit 1
    fi
  fi
}

alias setcp='find_pyserver_uncle'

# ***

