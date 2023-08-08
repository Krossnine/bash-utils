#!/bin/bash
set -e

#############################################################################################
# Bash utils over Github API
# https://docs.github.com/en/rest/quickstart?apiVersion=2022-11-28
#############################################################################################

function github_log() {
  echo >&2 "[GITHUB] $1"
}

function github_request() {
  local METHOD=$1
  local URL=$2
  local GITHUB_TOKEN=$3
  local DATA=$4
  local TMP_FILE=$(mktemp)
  http_code=$(curl -s --write-out '%{http_code}' --request "$METHOD" --url "$URL" \
          -H "Authorization: token $GITHUB_TOKEN" \
          --header "content-type: application/json" \
          -o "$TMP_FILE" \
          ${DATA:+ --data-raw "$DATA"} \
  )
  local CONTENT=$(cat "$TMP_FILE") && rm -rf TMP_FILE
  echo "$CONTENT"
  if ((http_code < 200 || http_code > 299)); then
    github_log "ERROR($http_code)($URL) : $DATA"
    exit 1
  fi
}

########################################################################################################################
# Get Github pull requests for a given repository
# github_list_pr "MY_USERNAME_OR_ORGA" "MY_REPO" "MY_PERSONAL_ACCESS_TOKEN"
########################################################################################################################
function github_list_pr() {
  local GITHUB_OWNER=$1
  local GITHUB_REPO=$2
  local GITHUB_TOKEN=$3

  local GITHUB_ENDPOINT="https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/pulls?state=open"
  github_request "GET" "$GITHUB_ENDPOINT" "$GITHUB_TOKEN"
}

########################################################################################################################
# Get Github pull requests comments for a given pull request
# github_get_pr_comments "MY_USERNAME_OR_ORGA" "MY_REPO" "MY_PERSONAL_ACCESS_TOKEN" "MY_PR_NUMBER"
########################################################################################################################
function github_get_pr_comments() {
  local GITHUB_OWNER=$1
  local GITHUB_REPO=$2
  local GITHUB_TOKEN=$3
  local GITHUB_ISSUE_NUMBER=$4
  local GITHUB_ENDPOINT="https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/issues/${GITHUB_ISSUE_NUMBER}/comments"
  github_request "GET" "$GITHUB_ENDPOINT" "$GITHUB_TOKEN"
}

########################################################################################################################
# Add comment for a given issue
# github_add_issue_comment "MY_USERNAME_OR_ORGA" "MY_REPO" "MY_PERSONAL_ACCESS_TOKEN" "MY_PR_NUMBER" "MY_COMMENT"
########################################################################################################################
function github_add_issue_comment() {
  local GITHUB_OWNER=$1
  local GITHUB_REPO=$2
  local GITHUB_TOKEN=$3
  local GITHUB_ISSUE_NUMBER=$4
  local GITHUB_COMMENT=$5
  local GITHUB_ENDPOINT="https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/issues/${GITHUB_ISSUE_NUMBER}/comments"
  local DATA_BODY=$(jq --null-input --arg b "$GITHUB_COMMENT" --arg env "$ENV" '{"body":$b}')

  github_request "POST" "$GITHUB_ENDPOINT" "$GITHUB_TOKEN" "$DATA_BODY"
}

function github_commit_and_push() {
  local branch=$1
  local message=$2
  ensure_parameter "$message" "Empty message parameter."
  github_log "Push changes to git on ${branch:--} with message = $message"
  if [[ -n "$branch" ]]; then
    git branch --set-upstream-to="origin/${branch}"
    git add . || true
    git commit -am "$message" || true
    git pull --rebase || true
    git push || true
  else
    github_log "Ignore commit and push (Empty branch parameter)"
  fi
}