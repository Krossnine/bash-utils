#!/bin/bash
set -e

# Bash script for directories operations

#
# Usage : ensure_directory_exists "/tmp/myDir" "directory should exist."
#
function ensure_directory_exists() {
  local directory_path=$1
  local error_message=$2
  if [ ! -d "$directory_path" ]; then
      echo "$error_message"
      exit 1
  fi
}

#
# List all sub directories for a path
# Usage :
#   list_subdirs <directory_path> <?recursive> <?maxdepth>
#
#   list_subdirs "/tmp/myDir"
#   list_subdirs "/tmp/myDir" true
#   list_subdirs "/tmp/myDir" true 3
#
function list_subdirs() {
  local directory_path=$1
  local recursive=${2:-false}
  local maxdepth=${3:-0}

  ensure_directory_exists "$directory_path" "Directory $directory_path should exist."

  if [ "$recursive" = true ]; then
    find "$directory_path" -mindepth 1 -maxdepth "$maxdepth" -type d
  else
    find "$directory_path" -maxdepth 1 -mindepth 1 -type d
  fi
}
