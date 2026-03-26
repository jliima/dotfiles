# Dotfiles stow instructions

Goal: `~/dotfiles` mirrors the structure of `~/`.

## Rule of thumb
- Put files in `~/dotfiles` at the same relative path they should have under `~/`.
- Then create symlinks from home to dotfiles (or use stow package dirs).
- Avoid moving unrelated files; only link what you manage.

## File example
Wanted target in home:
`~/.config/lnav/formats/installed/java-pipe-log.json`

Store source in repo:
`~/dotfiles/.config/lnav/formats/installed/java-pipe-log.json`

Create link:
`ln -s ~/dotfiles/.config/lnav/formats/installed/java-pipe-log.json ~/.config/lnav/formats/installed/java-pipe-log.json`

## Folder example
Wanted target folder in home:
`~/.config/lnav`

Store in repo:
`~/dotfiles/.config/lnav`

Create link:
`ln -s ~/dotfiles/.config/lnav ~/.config/lnav`

## Stow usage (from repo root)
If using package folders (e.g. `~/dotfiles/nvim/.config/nvim`):
- Link package: `stow -t "$HOME" nvim`
- Remove links: `stow -D -t "$HOME" nvim`

For this repo style (direct mirror under `~/dotfiles/.config/...`), use direct symlinks unless package dirs are introduced.
