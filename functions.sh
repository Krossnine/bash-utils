fn_exists() {
    declare -f -F $1 > /dev/null
    return $?
}

#
# Usage : trim "  blah  " returns "blah"
#
function trim() {
  local s=$1
  echo "$s" | xargs
}