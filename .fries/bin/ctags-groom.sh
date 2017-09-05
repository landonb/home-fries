#!/usr/bin/env bash

set -e

# ctags doesn't handle negative look behinds so instead this script
# strips false positives out of a tags file.

ctags "$@"

FILE="tags"

while [[ $# > 1 ]]
do
key="$1"

case $key in
    -f)
    FILE="$2"
    shift
    ;;
esac
shift
done

# Filter out false matches from class method regex
sed -i '' -E '/^(if|switch|function|module\.exports|it|describe)	.+language:js$/d' $FILE

# Filter out false matches from object definition regex
sed -i '' -E '/var[ 	]+[a-zA-Z0-9_$]+[ 	]+=[ 	]+require\(.+language:js$/d' $FILE

