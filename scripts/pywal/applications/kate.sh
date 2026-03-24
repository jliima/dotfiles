#!/usr/bin/env bash
set -eu

CACHE_DIR="$HOME/.cache/wal"

SOURCE_FILE="$CACHE_DIR/colors-kate.theme"
TARGET_DIR="$HOME/.local/share/org.kde.syntax-highlighting/themes"
TARGET_FILE="$TARGET_DIR/pywal-colors.theme"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"
cp "$SOURCE_FILE" "$TARGET_FILE" && echo "Copied $SOURCE_FILE to $TARGET_FILE"

####### TODO #######
# Fix below part

#kate_windows=$(xdotool search --onlyvisible --class kate)
#
#if [ -z "$kate_windows" ]; then
#  echo "There are no open kate instances, exiting."
#  exit 1
#fi
#
#file_paths=()
#unsaved_changes=()
#pids_to_kill=()
#files_to_reopen=()
#
#echo "Open kate instances found, reloading them"
#
#for window in $kate_windows; do
#  window_title=$(xdotool getwindowname "$window")
#  pid=$(xdotool getwindowpid "$window")
#
#  file_name=$(echo "$window_title" | grep -oP '.*(?= @)')
#  directory_path=$(echo "$window_title" | grep -oP '(?<=@ ).*(?= — Kate)' | xargs)
#
#  if [ ! -z "$file_name" ] && [ ! -z "$directory_path" ]; then
#    file_path="$directory_path/$file_name"
#    file_path="${file_path/#\~/$HOME}"
#
#    file_paths+=("$file_path")
#
#    if [[ "$window_title" == *'*'* ]]; then
#      unsaved_changes+=("$window_title")
#    else
#      pids_to_kill+=("$pid")
#      files_to_reopen+=("$file_path")
#    fi
#  else
#    echo "Can't find file path for kate instance $window_title"
#  fi
#done
#
#if [ ${#unsaved_changes[@]} -ne 0 ]; then
#  echo "At least one kate instance has unsaved changes, it won't be reloaded:"
#  for unsaved in "${unsaved_changes[@]}"; do
#    echo "  - \"$unsaved\""
#  done
#fi
#
#for pid in "${pids_to_kill[@]}"; do
#  echo "Killing kate instance with pid: $pid"
#  kill "$pid"
#done
#
#for path in "${files_to_reopen[@]}"; do
#  echo "Reopening kate for file path: $path"
#  kate -n "$path" &
#done
#