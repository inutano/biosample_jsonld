#!/bin/sh

WORKDIR="${1}"
BIOSAMPLE_ID="${2}"

cd "${WORKDIR}"

# Install rubygems
bundle install

# Run ruby script
ruby "biosample_ld.rb" "${BIOSAMPLE_ID}"
