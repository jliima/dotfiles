#!/usr/bin/env bash
set -eu

CACHE_DIR="$HOME/.cache/wal"

TARGET_DIR="$HOME/.config/QtProject/qtcreator/styles"
TARGET_DIR_2="$HOME/.config/QtProject/qtcreator/themes"

SOURCE_FILE="$CACHE_DIR/qtcreator-colors.xml"
SOURCE_FILE2="$CACHE_DIR/qtcreator-theme.creatortheme"
SOURCE_FILE3="$CACHE_DIR/qtcreator-theme.figmatokens"

TARGET_FILE="$TARGET_DIR/pywal-colors.xml"
TARGET_FILE_2="$TARGET_DIR_2/pywal-theme.creatortheme"
TARGET_FILE_3="$TARGET_DIR_2/pywal-theme.figmatokens"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"
mkdir -p "$TARGET_DIR_2"

cp "$SOURCE_FILE" "$TARGET_FILE" && echo "Copied $SOURCE_FILE to $TARGET_FILE"
cp "$SOURCE_FILE2" "$TARGET_FILE_2" && echo "Copied $SOURCE_FILE2 to $TARGET_FILE_2"
cp "$SOURCE_FILE3" "$TARGET_FILE_3" && echo "Copied $SOURCE_FILE3 to $TARGET_FILE_3"

# TODO fix at some point, this is a bit hacky
#OPENT_INSTANCES=$(pidof qtcreator)
#
#if [ -n "$OPENT_INSTANCES" ]; then
#  echo "Open instances of qtcreator found, restarting them"
#  killall qtcreator
#  $HOME/Qt/Tools/QtCreator/bin/qtcreator -lastsession 2>/dev/null 1>&2 &
#fi
