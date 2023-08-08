
#
# Usage : unsource_env_file "/path/myEnv.env"
#
function unsource_env_file() {
  local env_file=$1
  local env_file_vars=( $(cat "$env_file" | cut -d "=" -f1) )
  for env_file_var in "${env_file_vars[@]}"; do
    unset "$env_file_var"
  done
}