function teams_request() {
  local url=$1 data=$2

  http_code=$(curl -s -L --write-out '%{http_code}' \
          --url "${url}" \
          -H "Content-Type: application/json" \
          -d "${data}" \
  )

  if ((http_code < 200 || http_code > 299)); then
    echo "ERROR($http_code)($webhook_url) : $data"
  fi
}

########################################################################################################################
# Send a message on microsoft teams
# teams_send_message "https://mywebhook" "MyTitle" "MyMessage" "MyColor"
########################################################################################################################
function teams_send_message() {
  local webhook_url=$1 title=$2 message=$3 color=$4

  ensure_parameter "$webhook_url" "Empty webhook parameter."
  ensure_parameter "$title" "Empty title parameter."
  ensure_parameter "$message" "Empty message parameter."
  ensure_parameter "$color" "Empty color parameter."

  DATA_BODY=$(jq --null-input --arg title "$title" --arg color "$color" --arg message "$message" \
    '{"title": $title, "text": $message, "themeColor": $color }')

  teams_request "$webhook_url" "$DATA_BODY"
}