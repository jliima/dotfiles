#!/usr/bin/env bash
# Capture every app screenshot (or the given subset) and stitch the
# results into one labeled grid image, for a quick at-a-glance check of
# how the current pywal theme looks across apps.
#
# Usage: collage.sh [-o FILE] [-l LANG|all] [app...]
#   -o FILE   where to write the collage PNG (default:
#             ~/.cache/wal-screenshots/collage.png)
#   -l LANG   forwarded to capture.sh (default: java)
#   app...    forwarded to capture.sh (default: every installed app)
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_cmd montage || { log_err "imagemagick's montage is required but not found"; exit 1; }

COLLAGE_FILE="$DEFAULT_OUTPUT_DIR/collage.png"
LANG_ARG="java"

while getopts "o:l:h" opt; do
  case "$opt" in
    o) COLLAGE_FILE="$OPTARG" ;;
    l) LANG_ARG="$OPTARG" ;;
    h) grep '^#' "$0" | cut -c3-; exit 0 ;;
    *) exit 1 ;;
  esac
done
shift $((OPTIND - 1))

SHOTS_DIR="$(mktemp -d)"
trap 'rm -rf "$SHOTS_DIR"' EXIT

"$SCREENSHOT_DIR/capture.sh" -o "$SHOTS_DIR" -l "$LANG_ARG" "$@"

mapfile -t images < <(find "$SHOTS_DIR" -maxdepth 1 -name '*.png' | sort)
if [[ ${#images[@]} -eq 0 ]]; then
  log_err "No screenshots were captured, nothing to collage"
  exit 1
fi

mkdir -p "$(dirname "$COLLAGE_FILE")"
montage "${images[@]}" \
  -tile 4x -geometry 480x300+8+8 \
  -background '#10171e' -fill '#cfdceb' -pointsize 18 \
  -label '%t' \
  "$COLLAGE_FILE"

log_ok "Collage written to $COLLAGE_FILE (${#images[@]} shots)"
