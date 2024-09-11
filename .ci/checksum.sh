#!/bin/bash

# Define variables
SCRIPT_FILE="nurse.sh"
LAUNCHER_FILE="run.sh"
CHECKSUM_FILE="nurse.sh.sha256"

# Verify checksum against the local checksum file
if [ ! -f "$CHECKSUM_FILE" ]; then
  echo "Error: Checksum file ($CHECKSUM_FILE) not found. Please create it before committing."
  exit 1
fi

# Extract the local checksum
local_checksum=$(sha256sum "$SCRIPT_FILE" | awk '{print $1}')
stored_checksum=$(cat "$CHECKSUM_FILE")

# Check if the local checksum matches the stored checksum
if [ "$local_checksum" != "$stored_checksum" ]; then
  echo "Error: The checksum of $SCRIPT_FILE does not match the stored checksum in $CHECKSUM_FILE."
  echo "Updating checksum..."
  echo "$local_checksum" >"$CHECKSUM_FILE"
  git add "$CHECKSUM_FILE"
  echo "Checksum updated. Please commit again."
  exit 1
fi

# Run shellcheck on both the launcher and script
echo "Running shellcheck..."
if ! shellcheck "$SCRIPT_FILE"; then
  echo "Shellcheck failed for $SCRIPT_FILE. Please fix the issues before committing."
  exit 1
fi

if ! shellcheck "$LAUNCHER_FILE"; then
  echo "Shellcheck failed for $LAUNCHER_FILE. Please fix the issues before committing."
  exit 1
fi

echo "Pre-commit checks passed."
