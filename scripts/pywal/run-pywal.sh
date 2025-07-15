#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


# Run pywal with all provided arguments
wal "$@"

# Define applications directory relative to the script location
APPLICATIONS_DIR="${SCRIPT_DIR}/applications"

# Verify applications directory exists
if [ ! -d "$APPLICATIONS_DIR" ]; then
    echo "Error: Applications directory not found: $APPLICATIONS_DIR" >&2
    exit 1
fi

# Execute all executable scripts in applications directory sequentially in alphabetical order
find "$APPLICATIONS_DIR" -maxdepth 1 -type f -name '*.sh' -print0 | \
  sort -z | \
  while IFS= read -r -d $'\0' script; do
    if [ -x "$script" ]; then
        echo "Running: $script"
        "$script"
    else
        echo "Skipping non-executable: $script" >&2
    fi
done
