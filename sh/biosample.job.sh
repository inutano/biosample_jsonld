#!/bin/bash
#$ -S /bin/bash -j y
set -eux

XML_PATH="${1}"
jobconf="${2}"
WORK_DIR="$(dirname ${XML_PATH})"

TTL_DIR="${WORK_DIR}/ttl"
mkdir -p "${TTL_DIR}"

# SGE_TASK_ID=1 # For standalone testing
job_param="$(cat ${jobconf} | awk -v id=${SGE_TASK_ID} 'NR==id')"
job_name="biosample.$(echo ${job_param} | sed -e 's:,.*$::')"
ttl_path="${TTL_DIR}/${job_name}.ttl"

if [[ ! -e "${ttl_path}" ]]; then
  # Load rbenv
  export PATH="/home/inutano/.rbenv/bin:${PATH}"
  eval "$(rbenv init -)"
  # Generate a subset of xml and generate ttl
  cd "/home/inutano/repos/biosample_jsonld"
  ./bs2ld xml2ttl <(cat "${XML_PATH}" | sed -n "${job_param}") |\
    | grep -v "^@base" | grep -v "^@prefix" > "${ttl_path}"
fi
