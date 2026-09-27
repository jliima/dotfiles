#!/usr/bin/env bash
# Nano pywal syntax-highlighting application script.
# Deploys a per-language nanorc (Java/Shell/Python/CSS/XML, matching
# IntelliJ's colors) and makes sure ~/.nanorc includes it after the
# system defaults, so it takes over highlighting for those file types.
set -euo pipefail

CACHE_DIR="$HOME/.cache/wal"
SOURCE_FILE="$CACHE_DIR/colors-nano-lang.nanorc"
TARGET_DIR="$HOME/.config/nano"
TARGET_FILE="$TARGET_DIR/pywal-lang.nanorc"
NANORC="$HOME/.nanorc"
INCLUDE_LINE="include \"$TARGET_FILE\""

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "Error: $SOURCE_FILE not found. Run pywal first." >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
cp "$SOURCE_FILE" "$TARGET_FILE"
echo "Copied $SOURCE_FILE to $TARGET_FILE"

[[ -f "$NANORC" ]] || : > "$NANORC"
if ! grep -qF "$INCLUDE_LINE" "$NANORC"; then
  {
    echo ""
    echo "# Added by dotfiles/scripts/pywal/applications/nano.sh"
    echo "$INCLUDE_LINE"
  } >> "$NANORC"
  echo "Added include line to $NANORC"
else
  echo "$NANORC already includes $TARGET_FILE"
fi
