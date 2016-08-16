#!/bin/bash
# Last Modified: 2016-08-01

PHOTO_SRC_ROOT="/media/$USER/CANON_DC/DCIM"
PHOTO_DST_ROOT="/jus/photos/landon"

# Skipping: CANON_DC/DCIM/CANONMSC/*

this_month=$(date +%m)
this_year=$(date +%Y)

echo "Welcome to dubsacks camera copy in this ${this_month} of ${this_year}."
echo

copy_canon_assets () {

  for subdir in $(/bin/ls ${PHOTO_SRC_ROOT}); do

    if [[ $subdir != "CANONMSC" ]]; then
      # Split directory name string on delimiter [in Bash].
      # https://stackoverflow.com/questions/918886/how-do-i-split-a-string-on-a-delimiter-in-bash
      unique_id=$(echo $subdir | /bin/sed -r 's/([^_]+)_+(.*)/\1/g')
      month_1_12=$(echo $subdir | /bin/sed -r 's/([^_]+)_+(.*)/\2/g')

      # If parameter is 0-prefixed, you'll get
      #  ./canon_copy.sh: line 27: [[: 08: value too great for base (error token is "08")
      photo_year=$this_year
      if [[ ${month_1_12#0} -gt ${this_month#0} ]]; then
        photo_year=$(($photo_year - 1))
      fi
      photo_month=$month_1_12

      PHOTO_DST="${PHOTO_DST_ROOT}/${photo_year}/${photo_month}"
      PHOTO_SRC="${PHOTO_SRC_ROOT}/${subdir}"

      shopt -s nocaseglob

      if [[ -d ${PHOTO_SRC} ]]; then
        pushd ${PHOTO_SRC} &> /dev/null
        NUM_ASSETS_SRC=$(ls -1 *.JPG *.CR2 | wc -l)
        popd &> /dev/null
      else
        echo "No dir. at ${PHOTO_SRC}? Something seriously wrong."
        exit 1
      fi
      #
      if [[ -d ${PHOTO_DST} ]]; then
        pushd ${PHOTO_DST} &> /dev/null
        NUM_ASSETS_DST=$(ls -1 *.JPG *.CR2 | wc -l)
        popd &> /dev/null
      else
        /bin/mkdir ${PHOTO_DST}
        NUM_ASSETS_DST="none yet"
      fi

      echo "id: $unique_id / mon1_12: $month_1_12 / photo_yr: $photo_year / photo_mon: $photo_month"
      printf "No. assets in %-45s: %s\n" ${PHOTO_SRC} ${NUM_ASSETS_SRC}
      printf "No. assets in %-45s: %s\n" ${PHOTO_DST} ${NUM_ASSETS_DST}

      echo "/bin/cp -arn ${PHOTO_SRC}/"'*'" ${PHOTO_DST}"

      # Include dot-prefixed files.
      #shopt -s dotglob

      /bin/cp -arn ${PHOTO_SRC}/* ${PHOTO_DST}

      echo
      echo "Processed: ${PHOTO_DST}"
      echo
    else
      echo "Skipping subdir: $subdir "
    fi
  done

}

copy_canon_assets

