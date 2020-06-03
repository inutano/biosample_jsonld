#!/bin/bash
#
# usage:
#   biosample.run.sh <path to biosample_set.xml.gz>
# designed for DDBJ SC DBCLS node
#
set -x

# Directories
BASE_DIR="/home/inutano/repos/biosample_jsonld"
DATA_DIR="${BASE_DIR}/data"
WORK_DIR="${DATA_DIR}/$(date +%Y%m%d)"
SH_DIR="${BASE_DIR}/sh"
mkdir -p "${WORK_DIR}" && cd "${WORK_DIR}"

# Unarchive biosample_set.xml.gz
GZ_PATH="${1}"
if [[ ! -e "${GZ_PATH}" ]]; then
  url="ftp://ftp.ncbi.nlm.nih.gov/biosample/biosample_set.xml.gz"
  wget ${url}
  GZ_PATH="${WORK_DIR}/$(basename ${url})"
fi

XML_PATH="${WORK_DIR}/$(basename "${GZ_PATH}" .gz)"
if [[ ! -e "${XML_PATH}" ]]; then
  gunzip -c "${GZ_PATH}" > "${XML_PATH}"
fi

# Create jobconf file
cd "${WORK_DIR}"
if [[ ! -e "${WORK_DIR}/bs.00" ]]; then
  cat "${XML_PATH}" | grep -n '</BioSample>' |\
    awk -F':' 'BEGIN{ start=3 } NR%10000==0 { print start "," $1 "p"; start=$1+1 }' |\
    split -l 5000 -d - "bs."
fi

# Run on UGE
source "/home/geadmin/UGED/uged/common/settings.sh"
find ${WORK_DIR} -name "bs.*" | sort | while read jobconf; do
  jobname=$(basename ${jobconf})
  qsub -N "${jobname}" -o /dev/null -pe def_slot 1 -l s_vmem=4G -l mem_req=4G \
    -t 1-$(wc -l "${jobconf}" | awk '$0=$1'):1 \
    "${SH_DIR}/biosample.job.sh" "${XML_PATH}" "${jobconf}"
done
