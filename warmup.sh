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

function get_sha1_from_url() {
  local url=$1
  echo -n $url | sha1sum | awk '{print $1}'
}

########################################################################################################################
# Warmup a list of urls using an headless browser
# Usage :
# warmup_urls=(https://www.domain.com https://www.another.com)
# warmup_headless "DESKTOP" "${warmup_urls[@]}" for desktop view
# warmup_headless "MOBILE" "${warmup_urls[@]}" for mobile view
########################################################################################################################
function warmup_headless() {
  local device=${1:-"DESKTOP"}
  shift
  local urls=("$@")
  mkdir -p screenshots && chmod ugo+w screenshots

  for i in "${urls[@]}"; do
    local URL=$i
    case $device in
      "MOBILE") window_size="412,732";;
      *) window_size="1200,800";;
    esac

    docker container run -it -d --rm -v $(pwd)/screenshots:/usr/src/app zenika/alpine-chrome:latest --no-sandbox --screenshot=screenshot.png --hide-scrollbars --window-size=$window_size "$URL"

    while inotifywait --timeout 2 --event create screenshots;
      do echo "Waiting for file screenshot.png";
    done

    screenshot_id=$( get_sha1_from_url "$URL")

    if [ -e screenshots/screenshot.png ]
    then
      echo "Screenshot was generated"
      mv screenshots/screenshot.png screenshots/screenshot_device_"$device"_for_"$screenshot_id".png
    fi
  done
}