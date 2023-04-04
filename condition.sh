#!/bin/bash
set -e

#
# myArray=("blah" "anotherString" "ok")
# Usage : exists_in_array "blah" "${myArray[@]}"
#
function exists_in_array() {
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
  return 1
}

#
# myArray=("blah" "anotherString" "ok")
# Usage : ensure_in_array "blah" "${myArray[@]}"
#
function ensure_in_array() {
  local search_value=$1
  shift
  local array=("$@")
  if ! exists_in_array "$search_value" "${array[@]}"; then
      echo >&2 "Invalid value $search_value. Should match : ${array[@]}"
      exit 1
  fi
}