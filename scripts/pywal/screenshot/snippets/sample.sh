#!/usr/bin/env bash
# Sample exercising every pywal shell syntax color: comment, string,
# variable, keyword and external command.
set -euo pipefail

RETRIES=3
NAME="pywal"

for i in $(seq 1 "$RETRIES"); do
  if [[ "$i" -eq 1 ]]; then
    echo "Hello, ${NAME}! (attempt $i)"
  else
    printf 'Hello, %s! (attempt %s)\n' "$NAME" "$i"
  fi
done

git status
