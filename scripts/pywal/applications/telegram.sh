#!/usr/bin/env bash

# https://desktop.telegram.org/

# sudo mv Downloads/Telegram /opt/ && \ 
# mv /opt/Telegram && \ 
# ./Telegram
#
# sudo mv /usr/local/share/walogram/constants.tdesktop-theme /usr/local/share/walogram/constants.tdesktop-theme_backup
# sudo ln -s $HOME/.cache/wal/colors-telegram.tdesktop-theme /usr/local/share/walogram/constants.tdesktop-theme

set -eu

walogram -s
