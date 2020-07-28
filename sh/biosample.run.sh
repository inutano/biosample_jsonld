#!/bin/bash
#
# usage:
#   biosample.run.sh [work_dir]
# designed for DDBJ SC DBCLS node
#
# set -x

#
# Setup directories
#
SCRIPT_DIR=$(cd $(dirname ${0}) && pwd -P)
JOB_SCRIPT="${SCRIPT_DIR}/biosample.job.sh"

if [[ -z ${1} ]]; then
  WORK_DIR="/home/inutano/repos/biosample_jsonld/data/$(date +%Y%m%d)"
else
  mkdir -p "${1}"
  WORK_DIR=$(cd ${1} && pwd -P)
fi
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

#
# Download xml file
#

BS_XML_URL="ftp://ftp.ncbi.nlm.nih.gov/biosample/biosample_set.xml.gz"
XML_PATH="${WORK_DIR}/$(basename "${BS_XML_URL}" .gz)"
if [[ ! -e ${XML_PATH} ]]; then
  lftp -c "open $(dirname ${BS_XML_URL}) && pget -n 8 $(basename ${BS_XML_URL})"
  gunzip -c $(basename ${BS_XML_URL}) > ${XML_PATH}
fi

#
# Create jobconf file if not found
#
if [[ ! -e "${WORK_DIR}/bs.00" ]]; then
  grep -n '</BioSample>' "${XML_PATH}" |\
    awk -F':' 'BEGIN{ start=3 } NR%10000==0 { print start "," $1 "p"; start=$1+1 }' |\
    split -l 5000 -d - "bs."
fi

#
# Run on UGE
#
source "/home/geadmin/UGED/uged/common/settings.sh"
find ${WORK_DIR} -name "bs.*" | sort | while read jobconf; do
  jobname=$(basename ${jobconf})
  qsub -N "${jobname}" -o /dev/null -pe def_slot 1 -l s_vmem=4G -l mem_req=4G \
    -t 1-$(wc -l "${jobconf}" | awk '$0=$1'):1 \
    "${JOB_SCRIPT}" "${XML_PATH}" "${jobconf}"
done

#
# Wait for jobs to finish
#
while :; do
  sleep 30
  running_jobs=$(qstat | grep "bs.")
  if [[ -z ${running_jobs} ]]; then
    printf "All jobs finished.\n"
    break
  fi
done
