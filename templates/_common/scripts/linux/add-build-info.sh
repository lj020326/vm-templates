#!/usr/bin/env bash

set -e
set -x

TEMPLATE_BUILD_INFO_FILEPATH="/etc/.vm-template.env"
TEMPLATE_BUILD_INFO_ANSIBLE_FACTS_FILEPATH="/etc/ansible/facts.d/vm-template-build.fact"

## ref: https://www.google.com/search?q=bash+associative+array+to+json&sca_esv=4b1e09beaa1370b6&sxsrf=AHTn8zqiJz0TYV0kKjSE4sDunMjS5HIhMQ%3A1740621195297&ei=i8W_Z-7gEful5NoP2oDmSQ&ved=0ahUKEwiu0qKg3-KLAxX7ElkFHVqAOQkQ4dUDCBA&uact=5&oq=bash+associative+array+to+json&gs_lp=Egxnd3Mtd2l6LXNlcnAiHmJhc2ggYXNzb2NpYXRpdmUgYXJyYXkgdG8ganNvbjILEAAYgAQYkQIYigUyBhAAGAgYHjIIEAAYgAQYogRIkDFQsBNYzS9wBHgBkAEAmAF_oAHeCaoBBDExLjO4AQPIAQD4AQGYAhKgApkKwgIKEAAYsAMY1gQYR8ICBhAAGAcYHsICBxAAGIAEGA3CAggQABgHGAgYHsICBhAAGA0YHsICBRAAGO8FwgIIEAAYBRgNGB7CAggQABiiBBiJBZgDAIgGAZAGCJIHBDEzLjWgB5Q6&sclient=gws-wiz-serp
# Function to convert associative array to JSON
array_to_json() {
  local json="{"
  local count=0
  local key

  # Iterate through the keys of the associative array
  for key in "${!build_info_ansible_facts[@]}"; do
    # Add comma if it's not the first element
    if ((count > 0)); then
      json+=","
    fi
    # Add key-value pair to JSON string
    json+="\"$key\":\"${build_info_ansible_facts[$key]}\""
    ((count++))
  done
  json+="}"
  echo "$json"
}

function isInstalled() {
    command -v "${1}" >/dev/null 2>&1 || return 1
}

if [[ "$EUID" = 0 ]]; then
    echo "(1) set to root"
else
  echo "****************************"
  echo "** user is not root!"
  echo "**   This script must be run as root or with sudo, exiting"
  echo "****************************"
  exit 1
fi

echo '==> Add template build info'
echo "VM_TEMPLATE_BUILD_USERNAME=${BUILD_USERNAME}" > "${TEMPLATE_BUILD_INFO_FILEPATH}"
echo "VM_TEMPLATE_BUILD_JOB_URL=${BUILD_JOB_URL}" > "${TEMPLATE_BUILD_INFO_FILEPATH}"
echo "VM_TEMPLATE_BUILD_JOB_ID=${BUILD_JOB_ID}" >> "${TEMPLATE_BUILD_INFO_FILEPATH}"
echo "VM_TEMPLATE_BUILD_GIT_COMMIT_HASH=${BUILD_GIT_COMMIT_HASH}" >> "${TEMPLATE_BUILD_INFO_FILEPATH}"

# Requires bash with associative arrays
declare -A build_info_ansible_facts
build_info_ansible_facts["vm_template_build_username"]="${BUILD_USERNAME}"
build_info_ansible_facts["vm_template_build_job_url"]="${BUILD_JOB_URL}"
build_info_ansible_facts["vm_template_build_job_id"]="${BUILD_JOB_ID}"
build_info_ansible_facts["vm_template_build_git_commit_hash"]="${BUILD_GIT_COMMIT_HASH}"

echo '==> Add template ansible facts info'
mkdir -p /etc/ansible/facts.d
#echo "vm_template_build_username: ${BUILD_USERNAME}" > "${TEMPLATE_BUILD_INFO_ANSIBLE_FACTS_FILEPATH}"
#echo "vm_template_build_job_url: ${BUILD_JOB_URL}" >> "${TEMPLATE_BUILD_INFO_ANSIBLE_FACTS_FILEPATH}"
#echo "vm_template_build_job_id: ${BUILD_JOB_ID}" >> "${TEMPLATE_BUILD_INFO_ANSIBLE_FACTS_FILEPATH}"
#echo "vm_template_build_git_commit_hash: ${BUILD_GIT_COMMIT_HASH}" >> "${TEMPLATE_BUILD_INFO_ANSIBLE_FACTS_FILEPATH}"

#if [[ -z "$(isInstalled jq)" ]]; then
#  ## ref: https://stackoverflow.com/questions/57699438/using-jq-to-create-json-objects-dictionaries
#  for fact_key in "${!build_info_ansible_facts[@]}"
#  do
#      echo "$fact_key"
#      echo "${build_info_ansible_facts[$fact_key]}"
#  done |
#  jq -n -R 'reduce inputs as $i ({}; . + { ($i): (input|(tonumber? // .)) })' -f "${TEMPLATE_BUILD_INFO_ANSIBLE_FACTS_FILEPATH}"
# Convert and print the JSON output
json_output=$(array_to_json)
echo "$json_output" > "${TEMPLATE_BUILD_INFO_ANSIBLE_FACTS_FILEPATH}"

### set permissions
chmod 0644 "${TEMPLATE_BUILD_INFO_FILEPATH}"
cp -p "${TEMPLATE_BUILD_INFO_FILEPATH}" /home/${BUILD_USERNAME}/
