#!/bin/bash
# Tests for circleci.sh. No network: `curl` is replaced by a stub placed first in PATH.
# Usage: ./tests/circleci_test.sh

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CIRCLECI_SCRIPT="$REPO_DIR/circleci.sh"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

mkdir -p "$WORK_DIR/bin"
cat >"$WORK_DIR/bin/curl" <<'EOF'
#!/bin/bash
# curl stub. STUB_CURL_CODES: space separated http codes, one per call (the last one repeats).
out=""
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  [ "${args[i]}" = "-o" ] && out="${args[i + 1]}"
  [ "${args[i]}" = "--url" ] && url="${args[i + 1]}"
  [ "${args[i]}" = "--request" ] && method="${args[i + 1]}"
done
n=$(cat "$STUB_CURL_COUNT" 2>/dev/null || echo 0)
n=$((n + 1))
echo "$n" >"$STUB_CURL_COUNT"
echo "$method $url" >>"$STUB_CURL_LOG"
codes=($STUB_CURL_CODES)
idx=$((n - 1))
((idx >= ${#codes[@]})) && idx=$((${#codes[@]} - 1))
code=${codes[idx]}
if ((code < 200 || code > 299)); then
  body='{"message":"error"}'
elif [ "$method" = "POST" ]; then
  body='{"id":"pipeline-1"}'
elif [[ "$url" == */pipeline/*/workflow ]]; then
  body='{"items":[{"id":"wf-1"},{"id":"wf-2"}]}'
else
  body='{"status":"success"}'
fi
[ -n "$out" ] && printf '%s' "$body" >"$out"
printf '%s' "$code"
EOF
chmod +x "$WORK_DIR/bin/curl"

FAILURES=0
OUT="" ERR="" RC=0 CALLS=0

# run_case "<http codes>" "<bash snippet>": runs the snippet in a fresh bash that sources circleci.sh
# (which enables `set -e`, like in CI), with a fast polling configuration.
run_case() {
  export STUB_CURL_CODES="$1"
  export STUB_CURL_COUNT="$WORK_DIR/count" STUB_CURL_LOG="$WORK_DIR/calls.log"
  rm -f "$STUB_CURL_COUNT" "$STUB_CURL_LOG"
  OUT=$(PATH="$WORK_DIR/bin:$PATH" CIRCLE_CI_TOKEN=fake bash -c "
    source '$CIRCLECI_SCRIPT'
    CIRCLECI_POLL_INTERVAL=1
    CIRCLECI_POLL_TIMEOUT=2
    $2
  " 2>"$WORK_DIR/stderr")
  RC=$?
  ERR=$(cat "$WORK_DIR/stderr")
  CALLS=$(cat "$STUB_CURL_COUNT" 2>/dev/null || echo 0)
}

assert_eq() {
  if [ "$2" = "$3" ]; then
    echo "  ok   - $1"
  else
    echo "  FAIL - $1 (expected: '$3', got: '$2')"
    FAILURES=$((FAILURES + 1))
  fi
}

assert_contains() {
  if [[ "$2" == *"$3"* ]]; then
    echo "  ok   - $1"
  else
    echo "  FAIL - $1 (expected to contain: '$3', got: '$2')"
    FAILURES=$((FAILURES + 1))
  fi
}

echo "Script under test: $CIRCLECI_SCRIPT"

echo "1. workflows: 404 then 200 -> ids returned"
run_case "404 200" 'circleci_get_pipeline_workflow_ids pipeline-1'
assert_eq "exit code" "$RC" "0"
assert_eq "ids" "$OUT" $'wf-1\nwf-2'
assert_eq "curl called twice" "$CALLS" "2"

echo "2. workflows: 404 forever -> fails after timeout"
START=$SECONDS
run_case "404" 'circleci_get_pipeline_workflow_ids pipeline-1'
ELAPSED=$((SECONDS - START))
assert_eq "exit code" "$RC" "1"
assert_eq "no output on stdout" "$OUT" ""
assert_contains "explicit timeout message" "$ERR" "Timeout"
assert_contains "message mentions pipeline id" "$ERR" "pipeline-1"
assert_eq "retried more than once" "$((CALLS > 1))" "1"
assert_eq "took about the overridden timeout (2s..6s)" "$((ELAPSED >= 2 && ELAPSED <= 6))" "1"

echo "2b. wait_finished_pipeline propagates the timeout failure (set -e)"
run_case "404" 'circleci_wait_finished_pipeline pipeline-1; echo "NOT REACHED"'
assert_eq "exit code" "$RC" "1"
assert_eq "script stopped" "$OUT" ""

echo "2c. full flow: POST 201, workflow list 404 then 200, workflow status 200"
run_case "201 404 200 200 200" 'circleci_trigger_pipeline gh/Org/infra "{}"; echo DONE'
assert_eq "exit code" "$RC" "0"
assert_eq "flow completed" "$OUT" "DONE"

echo "3. circleci_request: errors still behave as before for other callers"
run_case "401" 'circleci_request GET https://circleci.com/api/v2/workflow/wf-1'
assert_eq "request exit code" "$RC" "1"
assert_eq "request still prints body" "$OUT" '{"message":"error"}'
assert_contains "request logs ERROR(401)" "$ERR" "ERROR(401)"
assert_eq "request: single call" "$CALLS" "1"

run_case "401" 'circleci_is_workflow_finished wf-1; echo "NOT REACHED"'
assert_eq "is_workflow_finished exit code" "$RC" "1"
assert_eq "is_workflow_finished stops script" "$OUT" ""
assert_eq "is_workflow_finished: no retry" "$CALLS" "1"

run_case "404" 'circleci_is_workflow_finished wf-1; echo "NOT REACHED"'
assert_eq "is_workflow_finished 404: exit code" "$RC" "1"
assert_eq "is_workflow_finished 404: no retry" "$CALLS" "1"

run_case "401" 'circleci_trigger_pipeline gh/Org/infra "{}"; echo "NOT REACHED"'
assert_eq "trigger_pipeline exit code" "$RC" "1"
assert_eq "trigger_pipeline stops script" "$OUT" ""
assert_eq "trigger_pipeline: POST not retried" "$CALLS" "1"

echo
if ((FAILURES > 0)); then
  echo "$FAILURES assertion(s) failed"
  exit 1
fi
echo "All tests passed"
