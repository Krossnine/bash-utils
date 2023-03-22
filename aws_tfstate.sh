#!/bin/bash
set -e

# Bash scripts for cloudposse tfstate-backend module
# https://registry.terraform.io/modules/cloudposse/tfstate-backend/aws/latest

BASH_UTILS_AWS_TFSTATE="AWS_TFSTATE"

function aws_tfstate_locks_count() {
  local TFSTATE_NAMESPACE=$1
  local TFSTATE_KEY=$2
  aws dynamodb scan \
       --table-name "$TFSTATE_NAMESPACE-lock" \
       --filter-expression "LockID = :lock" \
       --expression-attribute-values "{\":lock\":{\"S\":\"${TFSTATE_NAMESPACE}/${TFSTATE_KEY}.tfstate\"}}" \
       | jq -r '.Count' ;\
}

function aws_tfstate_locks_wait() {
    local TFSTATE_NAMESPACE=$1
    local TFSTATE_KEY=$2
    echo -n >&2 "[$BASH_UTILS_AWS_TFSTATE] Waiting for terraform locks to be released."
    until [ "$(aws_tfstate_locks_count "$TFSTATE_NAMESPACE" "$TFSTATE_KEY")" -lt "1" ]; do
      echo -n >&2 "."
      sleep 5
    done
    echo >&2 "" && echo >&2 "[$BASH_UTILS_AWS_TFSTATE] Terraform is ready (No locks found)."
}
