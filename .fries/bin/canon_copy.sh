#!/bin/bash
# Last Modified: 2016-06-14

PHOTO_SRC_ROOT="/media/$USER/CANON_DC/DCIM"
PHOTO_DST_ROOT="/jus/photos/landon"

# Skipping: CANON_DC/DCIM/CANONMSC/*

for subdir in $(/bin/ls ${PHOTO_SRC_ROOT}); do
  echo $subdir
  if [[ $subdir != "CANONMSC" ]]; then
    # Split directory name string on delimiter [in Bash].
    # https://stackoverflow.com/questions/918886/how-do-i-split-a-string-on-a-delimiter-in-bash
    unique_id=$(echo $subdir | /bin/sed -r 's/([^_]+)_+(.*)/\1/g')
    month_1_12=$(echo $subdir | /bin/sed -r 's/([^_]+)_+(.*)/\2/g')
    this_month=$(date +%m)
    this_year=$(date +%Y)

    photo_year=$this_year
    if [[ $month_1_12 -gt $this_month ]]; then
      photo_year=$(($photo_year - 1))
    fi
    photo_month=$month_1_12

    PHOTO_DST="${PHOTO_DST_ROOT}/${photo_year}/${photo_month}"
    PHOTO_SRC="${PHOTO_SRC_ROOT}/${subdir}"

  fi
done

