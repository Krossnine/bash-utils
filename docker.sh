#!/bin/bash
set -e

function debug() {
  echo "[DOCKER] $1" >&2
}

function docker_container_create() {
  local dockerImage=$1
  containerId=$(docker create "$dockerImage")
  debug "Create a container $containerId from $dockerImage "
  echo "$containerId"
}

function docker_container_remove() {
  local containerId=$1
  docker rm -f "$containerId" > /dev/null
  debug "Delete container with id=$containerId"
}

function docker_container_extract_env_vars() {
  local containerId=$1
  flatEnvs=$(docker inspect -f '{{.Config.Env}}' "$containerId" | cut -c2-)
  flatEnvs=${flatEnvs%?}
  debug "Extracted env vars from container $containerId = $flatEnvs"
  echo "$flatEnvs"
}

function docker_container_extract_env_value() {
  local containerId=$1
  local searchEnvName=$2
  IFS=' '
  read -ra envVars <<< "$(docker_container_extract_env_vars "$containerId")"
  for envVar in "${envVars[@]}";
  do
    currentEnvName="$(echo "$envVar" | cut -d "=" -f 1)"
    debug "Compare $searchEnvName with $currentEnvName"
    if [ "$searchEnvName" == "$currentEnvName" ]; then
      currentEnvValue=$(echo "$envVar" | cut -d "=" -f 2)
      debug "Found env var $searchEnvName with value = $currentEnvValue"
      echo "$currentEnvValue"
      return;
    fi
  done
}

function docker_image_extract_env_value() {
  local dockerImage=$1
  local searchEnvName=$2
  containerId=$(docker_container_create "$dockerImage")
  envValue=$(docker_container_extract_env_value "$containerId" "$searchEnvName")
  docker_container_remove "$containerId"
  echo "$envValue"
}

function extractDockerContent() {
  local dockerImage=$1
  local srcPath=$2
  local destPath=$3
  containerId=$(docker_container_create "$dockerImage")
  debug "Will extract $srcPath from $containerId to $destPath"
  docker cp "$containerId:$srcPath" "$destPath"
  docker_container_remove "$containerId"
}

function extractDockerWorkdir() {
  local dockerImage=$1
  local destPath=$2
  workdir=$(docker_image_extract_env_value "$dockerImage" "WORKDIR")
  extractDockerContent "$dockerImage" "$workdir" "$destPath"
}