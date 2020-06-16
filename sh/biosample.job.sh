#!/bin/bash
#$ -S /bin/bash -j y
# set -eux
module load docker

XML_PATH="${1}"
jobconf="${2}"
WORK_DIR="$(cd $(dirname ${XML_PATH}) && pwd -P)"

TTL_DIR="${WORK_DIR}/ttl"
mkdir -p "${TTL_DIR}"

# SGE_TASK_ID=1 # For standalone testing
job_param="$(cat ${jobconf} | awk -v id=${SGE_TASK_ID} 'NR==id')"
job_name="biosample.$(echo ${job_param} | sed -e 's:,.*$::')"
ttl_path="${TTL_DIR}/${job_name}.ttl"

if [[ ! -e "${ttl_path}" ]]; then
  tmp_xml=${ttl_path}.xml
  printf "<BioSampleSet>\n$(cat "${XML_PATH}" | sed -n "${job_param}")" > ${tmp_xml}

  docker run --security-opt seccomp=unconfined --rm \
    -e TZ=Asia/Tokyo \
    --volume ${TTL_DIR}:/work \
    "quay.io/inutano/biosample_jsonld:v1.3" \
    bs2ld \
    xml2ttl \
    /work/$(basename ${tmp_xml}) \
    > "${ttl_path}"
  rm -f ${tmp_xml}
fi

# validate
validation_output="${ttl_path}.validation"
valid_value='Validator finished with 0 warnings and 0 errors.'

docker run --security-opt seccomp=unconfined --rm \
   -v $(dirname "${ttl_path}"):/work \
   "quay.io/inutano/turtle-validator:v1.0" \
   ttl \
   /work/$(basename "${ttl_path}") \
   > "${validation_output}"``

if [[ $(cat "${validation_output}") == "${valid_value}" ]]; then
  rm -f "${validation_output}"
fi
