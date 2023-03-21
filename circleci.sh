#!/bin/bash
set -e

function circleci_request() {
  local METHOD=$1
  local URL=$2
  local DATA=$3
  local TMP_FILE=$(mktemp)
  http_code=$(curl -s --write-out '%{http_code}' --request "$METHOD" --url "$URL" \
          --header "Circle-Token: ${CIRCLE_CI_TOKEN}" \
          --header "content-type: application/json" \
          -o "$TMP_FILE" \
          ${DATA:+ --data "$DATA"} \
  )
  local CONTENT=$(cat "$TMP_FILE") && rm -rf TMP_FILE
  echo "$CONTENT"
  if ((http_code < 200 || http_code > 299)); then
    circleci_log "ERROR($http_code)($URL) : $DATA"
    exit 1
  fi
}

function circleci_log() {
  echo >&2 "[CIRCLECI] $1"
}

function circleci_is_workflow_finished() {
  local WORKFLOW_ID=$1
  response=$(circleci_request "GET" "https://circleci.com/api/v2/workflow/$WORKFLOW_ID")
  status=$(jq -r '.status' <<<"$response")
  if [[ "$status" =~ ^(running|on_hold)$ ]]; then
    echo 0
  else
    echo 1
  fi
}

function circleci_get_pipeline_workflow_ids() {
  local PIPELINE_ID=$1
  circleci_log "Get pipeline workflows for pipeline id = ${PIPELINE_ID}..."
  response=$(circleci_request "GET" "https://circleci.com/api/v2/pipeline/$PIPELINE_ID/workflow")
  jq -r '.items[].id' <<<"$response"
}

function circleci_wait_finished_workflow() {
  local WORKFLOW_ID=$1
  circleci_log "Waiting for workflow $WORKFLOW_ID."
  until [ "$(circleci_is_workflow_finished "$WORKFLOW_ID")" != "0" ]; do
    echo -n >&2 "."
    sleep 5
  done
  echo -n >&2 "\n"
  circleci_log "\nWorkflow $WORKFLOW_ID is finished..."
}

function circleci_wait_finished_pipeline() {
  local PIPELINE_ID=$1
  pipeline_workflow_ids=($(circleci_get_pipeline_workflow_ids "$PIPELINE_ID"))
  for i in "${pipeline_workflow_ids[@]}"; do
    circleci_wait_finished_workflow "$i"
  done
}

function circleci_trigger_pipeline() {
  local PROJECT_SLUG=$1
  local DATA_BODY=$2
  circleci_log "Trigger pipeline for $PROJECT_SLUG with $DATA_BODY"
  response=$(circleci_request "POST" "https://circleci.com/api/v2/project/${PROJECT_SLUG}/pipeline" "$DATA_BODY")
  PIPELINE_ID="$(jq -r '.id' <<<"$response")"
  circleci_wait_finished_pipeline "$PIPELINE_ID"
}

function circleci_debug() {
  local PIPELINE_ID=$1
  circleci_wait_finished_pipeline "$PIPELINE_ID"
}
