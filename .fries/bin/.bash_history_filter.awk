#!/bin/awk -f

# USAGE:
#
#   awk -f .bash_history_filter.awk ~/.bash_history > .bash_history_clean

function clear_histentry() {
  timestamp = ""
  arraysize = 0
  # I.e., histentry = []
  split("", histentry)
}

function check_histentry() {
  should_retain = 0
  if (arraysize > 0) {
    should_retain = 1
    for (ix = 1; ix <= arraysize; ix++) {
      if (histentry[ix] ~ /^['"] \| pass insert -m /) {
        should_retain = 0
        #print "DROPPING:", timestamp
        break
      }
    }
  }
  return should_retain
}

function print_histentry() {
  print timestamp
  for (ix = 1; ix <= arraysize; ix++) {
    print histentry[ix]
  }
}

function print_last_histentry() {
  should_retain = check_histentry()
  if (should_retain) {
    print_histentry()
  }
  clear_histentry()
}

/^#[[:digit:]]{10}$/ {
  print_last_histentry()
  timestamp = $0
  next
}

{
  histentry[++arraysize] = $0
}

END {
  print_last_histentry()
}

