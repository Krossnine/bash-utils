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

#
# Usage : ensure_parameter "$var" "$var should not be empty."
#
function ensure_parameter() {
  local parameter=$1
  local error_message=$2
  if [ -z "$parameter" ]; then
    echo "$error_message"
    exit 1
  fi
}

#
# Usage : ensure_file_exists "/tmp/myFile" "file should exist."
#
function ensure_file_exists() {
  local file_path=$1
  local error_message=$2
  if [ ! -f "$file_path" ]; then
      echo "$error_message"
      exit 1
  fi
}