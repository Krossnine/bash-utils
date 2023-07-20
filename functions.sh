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

#
# Sequentially iterate a function over an array in subshell
# Usage : iterate "myFunction" "${myArray[@]}"
#
alias iterate='iterate_seq'
function iterate_seq() {
  trap 'break' SIGINT
  local cmd=$1
  shift
  local array=("$@")

  for i in "${array[@]}"
  do
    $cmd "$i"
  done
}

#
# Parallel iterate a function over an array in subshell
# Usage : iterate "myFunction" "${myArray[@]}"
#
function iterate_parallel() {
  trap 'break' SIGINT
  local cmd=$1
  shift
  local array=("$@")

  for i in "${array[@]}"
  do
    $cmd "$i" &
  done
  wait
}
