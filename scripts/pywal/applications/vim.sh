#!/usr/bin/env bash
# Vim/Neovim pywal colorscheme application script.
# Deploys colors/pywal.vim to both Vim and Neovim's colors directories.
# Does NOT change which colorscheme is active (this machine's Neovim config
# uses tokyonight-night); run `:colorscheme pywal` to try it.
set -euo pipefail

CACHE_DIR="$HOME/.cache/wal"
SOURCE_FILE="$CACHE_DIR/colors-nvim.vim"

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "Error: $SOURCE_FILE not found. Run pywal first." >&2
  exit 1
fi

deployed=0
for colors_dir in "$HOME/.config/nvim/colors" "$HOME/.vim/colors"; do
  base_dir="$(dirname "$colors_dir")"
  if [[ -d "$base_dir" ]]; then
    mkdir -p "$colors_dir"
    cp "$SOURCE_FILE" "$colors_dir/pywal.vim"
    echo "Copied $SOURCE_FILE to $colors_dir/pywal.vim"
    ((deployed++)) || true
  fi
done

if [[ "$deployed" -eq 0 ]]; then
  echo "Neither ~/.config/nvim nor ~/.vim exist; nothing to deploy to." >&2
  exit 0
fi

echo "Run :colorscheme pywal in Vim/Neovim to try it."
