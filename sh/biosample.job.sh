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
  # Generate a subset of xml and generate ttl
  cd "/home/inutano/repos/biosample_jsonld"
  ./bs2ld xml2ttl <(cat <(echo "<BioSampleSet>") <(cat "${XML_PATH}" | sed -n "${job_param}")) > "${ttl_path}"
fi

# validate
validation_output="${ttl_path}.validation"
valid_value='Validator finished with 0 warnings and 0 errors.'

module load docker
image="quay.io/inutano/turtle-validator:v1.0"

docker run --rm -v $(dirname "${ttl_path}"):/work "${image}" ttl $(basename "${ttl_path}") > "${validation_output}"

if [[ $(cat "${validation_output}") == "${valid_value}" ]]; then
  rm -f "${validation_output}"
fi
