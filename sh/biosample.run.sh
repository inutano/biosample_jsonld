#!/bin/sh
#
# usage:
#   biosample.run.sh <path to biosample_set.xml.gz>
# designed for DDBJ SC DBCLS node
#
set -eux

# Directories
BASE_DIR="/home/inutano/repos/biosample_jsonld"
DATA_DIR="${BASE_DIR}/data"
WORK_DIR="${DATA_DIR}/$(date +%Y%d%m)"
SH_DIR="${BASE_DIR}/sh"
mkdir -p "${WORK_DIR}" && cd "${WORK_DIR}"

# Unarchive biosample_set.xml.gz
GZ_PATH="${1}"
XML_PATH="${WORK_DIR}/$(basename "${GZ_PATH}" .gz)"
gunzip -c "${GZ_PATH}" > "${XML_PATH}"

# Create jobconf file
cd "${WORK_DIR}"
cat "${XML_PATH}" | grep -n '</BioSample>' |\
  awk -F':' 'BEGIN{ start=1 } NR%10000==0 { print start "," $1 "p"; start=$1+1 }' |\
  split -l 5000 -d - "bs."

# Run on UGE
find ${WORK_DIR} -name "bs.*" | sort | while read jobconf; do
  jobname=$(basename ${jobconf})
  qsub -N "${jobname}" -o /dev/null -pe def_slot 1 -l s_vmem=4G -l mem_req=4G \
    -t 1-$(wc -l "${jobconf}" | awk '$0=$1'):1 \
    "${SH_DIR}/biosample.run.sh" "${XML_PATH}" "${jobconf}"
done
