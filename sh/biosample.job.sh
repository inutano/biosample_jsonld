#!/bin/bash
#$ -S /bin/bash -j y
# set -eux
module load docker

XML_PATH="${1}"
jobconf="${2}"
WORK_DIR="$(cd $(dirname ${XML_PATH}) && pwd -P)"

# For saving intermediate files
TMPDIR="/data1/tmp/biosample-lod/biosample/ttl"
mkdir -p "${TMPDIR}"

# For saving final output
TTL_DIR="${WORK_DIR}/ttl"
mkdir -p "${TTL_DIR}"

# SGE_TASK_ID=1 # For standalone testing
job_param="$(cat ${jobconf} | awk -v id=${SGE_TASK_ID} 'NR==id')"
job_name="biosample.$(echo ${job_param} | sed -e 's:,.*$::')"

ttl_path="${TTL_DIR}/${job_name}.ttl"
ttl_tmp_path="${TMPDIR}/${job_name}.ttl"

#
# Create partial XML
#
tmp_xml=${ttl_tmp_path}.xml
printf "<BioSampleSet>\n$(cat "${XML_PATH}" | sed -n "${job_param}")" > ${tmp_xml}

#
# Convert XML to ttl on tmpdir
#
docker run --security-opt seccomp=unconfined --rm \
  -e TZ=Asia/Tokyo \
  --volume ${TMPDIR}:/work \
  "quay.io/inutano/biosample_jsonld:v1.8" \
  bs2ld \
  xml2ttl \
  /work/$(basename ${tmp_xml}) \
  > "${ttl_tmp_path}"

#
# Validate ttl
#
validation_output="${ttl_tmp_path}.validation"
valid_value='Validator finished with 0 warnings and 0 errors.'

docker run --security-opt seccomp=unconfined --rm \
  -v $(dirname "${ttl_tmp_path}"):/work \
  "quay.io/inutano/turtle-validator:v1.0" \
  ttl \
  /work/$(basename "${ttl_tmp_path}") \
  > "${validation_output}"

if [[ $(cat "${validation_output}") == "${valid_value}" ]]; then
  rm -f "${validation_output}"
fi

#
# Move ttl file to final dest dir and remove XML
#
mv ${ttl_tmp_path} ${ttl_path}
rm -f ${tmp_xml}
