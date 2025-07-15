#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

$SCRIPT_DIR/run-pywal.sh --iterative -i "$HOME/Pictures/Wallpapers/Misc"
