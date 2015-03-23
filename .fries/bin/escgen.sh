#!/bin/bash

# Script: escgen

# Not My Script. Copied from:
#   http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/c583.html

function usage {
   echo -e "\033[1;34mescgen\033[0m <lower_octal_value> [<higher_octal_value>]"
   echo "   Octal escape sequence generator: print all octal escape sequences"
   echo "   between the lower value and the upper value.  If a second value"
   echo "   isn't supplied, print eight characters."
   echo "   1998 - Giles Orr, no warranty."
   exit 1
}

if [ "$#" -eq "0" ]
then
   echo -e "\033[1;31mPlease supply one or two values.\033[0m"
   usage
fi
let lower_val=${1}
if [ "$#" -eq "1" ]
then
   #   If they don't supply a closing value, give them eight characters.
   upper_val=$(echo -e "obase=8 \n ibase=8 \n $lower_val+10 \n quit" | bc)
else
   let upper_val=${2}
fi
if [ "$#" -gt "2" ]
then 
   echo -e "\033[1;31mPlease supply two values.\033[0m"
   echo
   usage
fi
if [ "${lower_val}" -gt "${upper_val}" ]
then
   echo -e "\033[1;31m${lower_val} is larger than ${upper_val}."
   echo
   usage
fi
if [ "${upper_val}" -gt "777" ]
   then
   echo -e "\033[1;31mValues cannot exceed 777.\033[0m"
   echo
   usage
fi

let i=$lower_val
let line_count=1
let limit=$upper_val
while [ "$i" -lt "$limit" ]
do
   octal_escape="\\$i"
   echo -en "$i:'$octal_escape' "
   if [ "$line_count" -gt "7" ]
   then 
      echo
      #   Put a hard return in.
      let line_count=0
   fi
   let i=$(echo -e "obase=8 \n ibase=8 \n $i+1 \n quit" | bc)
   let line_count=$line_count+1
done
echo

