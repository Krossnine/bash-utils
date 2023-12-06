#!/bin/bash
set -e

function cloudfront_debug() {
  echo "[CLOUDFRONT] $1" >&2
}

function cloudfront_invalidate() {
  local cloudfront_id=$1
  local paths=${2:-'/*'}
  cloudfront_debug "Start cloudfront cache invalidation for $cloudfront_id with given paths:$paths"
  response=$(aws cloudfront create-invalidation --distribution-id "$cloudfront_id" --path "$paths")
  INVALIDATION_ID=$(jq -r '.Invalidation.Id' <<<"$response")
  aws cloudfront wait invalidation-completed --id "$INVALIDATION_ID" --distribution-id "$cloudfront_id"
  cloudfront_debug "End of cloudfront cache invalidation for $cloudfront_id with given paths:$paths"
  echo "$INVALIDATION_ID"
}