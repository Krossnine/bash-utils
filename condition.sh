#!/bin/bash
set -e

#
# myArray=("blah" "anotherString" "ok")
# Usage : exists_in_array "blah" "${myArray[@]}"
#
function exists_in_array() {
  local value=$1
  local array=$2
  [[ " ${array[*]} " =~ " ${value} " ]] && echo 0 || echo 1
}
