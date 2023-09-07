#!/bin/bash

function install() {
  local INSTALL_PATH=${1:-./}
  FILENAMES=(
    "functions.sh"
    "circleci.sh"
    "aws_tfstate.sh"
    "condition.sh"
    "github.sh"
    "dir.sh"
    "env_var.sh"
    "warmup.sh"
  )
  for filename in "${FILENAMES[@]}"; do
    FILEPATH="$INSTALL_PATH/$filename"
    source "$FILEPATH"
  done

  fn_exists circleci_log && echo "Successful installation of bash-utils" || echo "Error on bash-utils install"
}

function installFromGit() {
  INSTALL_PATH="$(mktemp -d)/bash-utils"
  git clone --quiet "https://github.com/Krossnine/bash-utils.git" "$INSTALL_PATH"
  install "$INSTALL_PATH"
  rm -rf "$INSTALL_PATH"
}

installFromGit