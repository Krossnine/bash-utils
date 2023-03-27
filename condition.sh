#!/bin/bash
set -e

#
# myArray=("blah" "anotherString" "ok")
# Usage : ensure_in_array "blah" "${myArray[@]}"
#
function ensure_in_array() {
  local search_value=$1
  shift
  local array=("$@")
  for i in "${array[@]}"
  do
      if [ "$i" == "$search_value" ]
      then
          return 0
      fi
  done
  echo >&2 "Invalid value $search_value. Should match : ${array[@]}"
  exit 1
}