#!/bin/bash

#
# Retry a bash command/function   iterate a function over an array in subshell
# Usage : retry "echo hello" 3 1
#    @command : command to run
#    @retries : max number of retries
#    @wait: number of seconds before retry (default : 0)
#
function retry() {
  local command=$1
  local retries=$2
  local wait=${3:-0}
  local options="$-"

  if [[ $options == *e* ]]; then
    set +e
  fi

  $command
  local exit_code=$?

  if [[ $options == *e* ]]; then
    set -e
  fi

  if [[ $exit_code -ne 0 && $retries -gt 0 ]]; then
    sleep "$wait"
    retry "$command" $((retries - 1)) "$wait"
  else
    return $exit_code
  fi
}