#!/bin/bash
set -e

function aws_assume_role() {
  if [ "$#" -ne 2 ]
  then
    echo "Usage: source aws_assume_role.sh [account_id] [role]"
    exit 1
  fi

  account_id="$1"
  role="$2"

  role_session_name=`cat /proc/sys/kernel/random/uuid 2>/dev/null || date | cksum | cut -d " " -f 1`
  aws_credentials=$(aws sts assume-role \
      --role-arn "arn:aws:iam::${account_id}:role/$role" \
      --role-session-name "$role_session_name" \
      --duration-seconds 3600 \
      --output json)

  AWS_ACCESS_KEY_ID=$(echo "${aws_credentials}" | grep AccessKeyId | awk -F'"' '{print $4}' )
  AWS_SECRET_ACCESS_KEY=$(echo "${aws_credentials}" | grep SecretAccessKey | awk -F'"' '{print $4}' )
  AWS_SESSION_TOKEN=$(echo "${aws_credentials}" | grep SessionToken | awk -F'"' '{print $4}' )
  AWS_SECURITY_TOKEN=$(echo "${aws_credentials}" | grep SessionToken | awk -F'"' '{print $4}' )

  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export AWS_SESSION_TOKEN
  export AWS_SECURITY_TOKEN

  echo "session '$role_session_name' valid for 60 minutes"
}
