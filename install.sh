#!/bin/bash

INSTALL_PATH="$(mktemp -d)/bash-utils"
git clone --quiet "https://github.com/Krossnine/bash-utils.git" "$INSTALL_PATH"

FILENAMES=("functions.sh" "circleci.sh" "aws_tfstate.sh" "condition.sh")

for filename in "${FILENAMES[@]}"; do
  FILEPATH="$INSTALL_PATH/$filename"
  echo "Install $FILEPATH"
  source "$FILEPATH"
done

fn_exists circleci_log && echo "Successful installation of bash-utils" || echo "Error on bash-utils install"
rm -rf "$INSTALL_PATH"