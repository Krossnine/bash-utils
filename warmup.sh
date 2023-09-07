########################################################################################################################
# Warmup a list of urls.
# Usage :
# warmup_urls=(https://www.domain.com https://www.another.com)
# warmup "${warmup_urls[@]}"
########################################################################################################################
function warmup() {
  local urls=("$@")
  for i in "${urls[@]}"; do
      local URL=$i
      local start=`date +%s`
      http_code=$(curl -s --write-out '%{http_code}' --request "GET" --url "$URL" --output /dev/null)
      local end=`date +%s`
      local duration=`expr $end - $start`
      if ((http_code < 200 || http_code > 299)); then
        echo >&2 "ERROR($http_code)($URL) (Duration: $duration seconds)"
      else
        echo "Warmup url : $URL (Duration: $duration)"
      fi
  done
}