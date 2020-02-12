#!/bin/awk -f

# USAGE:
#
#   mkdir /tmp/testing-splits
#   cd /tmp/testing-splits
#   awk -f bash_function_to_file_splitter.awk some/long/bash/script.sh

# HINT: Put filenames in double quotes to redirect to specific files, e.g.,
#
#   { print > "path/to/some/file" }

{
  if (cur_filename == "") {
    cur_funcnumb = 0
    cur_filename = cur_funcnumb "__pre_func.sh"
    print "FILENAME: " cur_filename
  }
#  else {
#    cur_filename = cur_funcname ".sh"
#  }
}

/^[_a-zA-Z][_a-zA-Z0-9]*\s*\(\)\s*{$/ {
  print "FUNCTION:", $0
  match($0, /([_a-zA-Z][_a-zA-Z0-9]*)/, arr_funcname)
  print "FUNCNAME:", arr_funcname[1]
  cur_funcnumb += 1
  cur_filename = sprintf("%04d__%s.sh", cur_funcnumb, arr_funcname[1])
  print "FILENAME: " cur_filename

  # FIXME/2018-04-10: Add copy header.
}

{ print > cur_filename }

