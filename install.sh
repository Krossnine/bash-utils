#!/bin/bash

BASH_INSTALL_DIRECTORY=${BASH_INSTALL_DIRECTORY:-/tmp/bash-utils}
SCRIPTS_FILENAMES=(
    "aws_assume_role.sh"
    "aws_cloudfront.sh"
    "aws_tfstate.sh"
    "circleci.sh"
    "condition.sh"
    "dir.sh"
    "docker.sh"
    "env_var.sh"
    "functions.sh"
    "github.sh"
    "teams.sh"
    "warmup.sh"
    "retry.sh"
)
REMOTE_BRANCH_NAME="main"
REMOTE_INSTALL_PREFIX="https://raw.githubusercontent.com/Krossnine/bash-utils/$REMOTE_BRANCH_NAME"
CHECK_INSTALL_FUNCTION=circleci_log

function check_install() {
  fn_exists $CHECK_INSTALL_FUNCTION || echo "Error on bash-utils install"
}

function source_remote_script() {
  local url=$1
  local filename=$2
  TARGET_FILENAME="$BASH_INSTALL_DIRECTORY/$filename"
  if ! test -f "$TARGET_FILENAME"; then
    mkdir -p "$BASH_INSTALL_DIRECTORY"
    http_code=$(curl -s --write-out '%{http_code}' --request "GET" --url "$url" -o "$TARGET_FILENAME")
    if ((http_code < 200 || http_code > 299)); then
      echo "Could not download : $url"
    else
      # shellcheck disable=SC1090
      echo "Download script : $url"
    fi
  fi
  # shellcheck disable=SC1090
  source "$TARGET_FILENAME"
}

function __install() {
  local remote_install=${1:-true}

  for filename in "${SCRIPTS_FILENAMES[@]}"; do
    if [ "$remote_install" = true ] ; then
      source_remote_script "$REMOTE_INSTALL_PREFIX/$filename" "$filename"
    else
      # shellcheck disable=SC1090
      echo "Local install from $filename" && source "./$filename"
    fi
  done

  check_install
}

function local_install() {
  __install false
}

function remote_install() {
  __install true
}

remote_install