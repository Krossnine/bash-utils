fn_exists() {
    declare -f -F $1 > /dev/null
    return $?
}