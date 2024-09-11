#!/bin/bash

# Base URL for the script and checksum
BASE_URL="https://raw.githubusercontent.com/hxii/nurse/main"

# Script and checksum file names
SCRIPT_NAME="nurse.sh"
CHECKSUM_NAME="nurse.sh.sha256"

# Download checksum
CHECKSUM=$(curl -s "${BASE_URL}/${CHECKSUM_NAME}" | awk '{print $1}')

# Download script and verify checksum using a pipe
if curl -s "${BASE_URL}/${SCRIPT_NAME}" | tee >(sha256sum --check <(echo "${CHECKSUM}  -") >/dev/null) | bash; then
  echo "Checksum verification passed and script executed."
else
  echo "Checksum verification failed! Exiting." >&2
  exit 1
fi
