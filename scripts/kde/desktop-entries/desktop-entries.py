#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Name:        desktop-entries.py
# Description: Make room in ~/.local/share/applications for the stowed desktop
#              entries before stow runs, so a pull never stops on them.
#
# Details:
#   Some apps write their own desktop entry over the stowed link (Claude
#   desktop on update, Chromium when it refreshes a PWA), and stow then refuses
#   to link the repo's copy. Others name their entry per install (JetBrains
#   Toolbox puts a UUID in it, Chromium the profile folder), so the shortcuts
#   kde-sync shares would point at a different file on every machine.
#
#   For every entry in the dotfiles' .local/share/applications:
#
#     - a real file with the same name in ~/.local/share/applications is the
#       app's rewrite: it is moved to the backup folder, the dotfiles win.
#     - X-Dotfiles-Replaces=GLOB;GLOB; in [Desktop Entry] lists the app's own
#       entries that this one stands in for under a name that is the same
#       everywhere. Real files matching them are moved to the backup folder
#       too, but only while the entry's TryExec exists, so an app installed
#       elsewhere on this machine keeps its own entry.
#
#   Backups go to ~/.local/state/dotfiles/desktop-entries/<time>/. The git
#   hooks in .githooks run this before stow; run it by hand after an app
#   brought its entry back.
#
#   desktop-entries.py [-n]    (-n: only show what would be moved)
# ------------------------------------------------------------------------------

import argparse
import fnmatch
import os
import shutil
import sys
import time
from pathlib import Path

# ==== Configuration ====
HOME = Path.home()
REPO = Path(__file__).resolve().parents[3]
REL_DIR = Path(".local/share/applications")
REPO_APPS = REPO / REL_DIR
LOCAL_APPS = HOME / REL_DIR
STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "dotfiles/desktop-entries"
REPLACES_KEY = "X-Dotfiles-Replaces"


# ==== Colors ====
class Colors:
  """ANSI color codes for terminal output."""

  RESET = "\033[0m"
  BOLD = "\033[1m"
  RED = "\033[91m"
  GREEN = "\033[92m"
  YELLOW = "\033[93m"
  BLUE = "\033[94m"


# ==== Output helpers ====
def print_info(message):
  print(f"{Colors.BLUE}> {message}{Colors.RESET}")


def print_warn(message):
  print(f"{Colors.YELLOW}! {message}{Colors.RESET}", file=sys.stderr)


# ==== Desktop entries ====
def entry_keys(path):
  """The keys of the [Desktop Entry] group."""
  keys, group = {}, None
  for line in path.read_text(errors="replace").splitlines():
    line = line.strip()
    if line.startswith("["):
      group = line
    elif group == "[Desktop Entry]" and "=" in line and not line.startswith("#"):
      key, value = line.split("=", 1)
      keys[key.strip()] = value.strip()
  return keys


def is_repo_link(path, repo_file=None):
  """True if path is a link into the dotfiles (to repo_file, when given)."""
  if not path.is_symlink():
    return False
  target = path.resolve()
  return target == repo_file.resolve() if repo_file else REPO in target.parents


def try_exec_ok(keys):
  value = keys.get("TryExec")
  if not value:
    return True
  if "/" in value:
    return os.access(value, os.X_OK)
  return shutil.which(value) is not None


def plan():
  """(local file, reason) pairs to move out of the way."""
  moves = []
  for repo_file in sorted(REPO_APPS.glob("*.desktop")):
    local = LOCAL_APPS / repo_file.name
    if local.is_symlink() and not is_repo_link(local, repo_file):
      print_warn(f"{local} links somewhere else, left alone")
    elif local.exists() and not local.is_symlink():
      moves.append((local, "written by its app over the stowed link"))

    keys = entry_keys(repo_file)
    globs = [g for g in keys.get(REPLACES_KEY, "").split(";") if g]
    if not globs:
      continue
    if not try_exec_ok(keys):
      print_warn(f"{repo_file.name}: {keys['TryExec']} is missing here, keeping the app's own entries")
      continue
    for local in sorted(LOCAL_APPS.iterdir()):
      if local.name == repo_file.name or is_repo_link(local) or not local.is_file():
        continue
      if any(fnmatch.fnmatchcase(local.name, g) for g in globs):
        moves.append((local, f"replaced by {repo_file.name}"))
  return moves


def main():
  parser = argparse.ArgumentParser(description="Move app-written desktop entries out of the way of the stowed ones.")
  parser.add_argument("-n", "--dry-run", action="store_true", help="only show what would be moved")
  args = parser.parse_args()

  moves = plan()
  if not moves:
    return
  backup = STATE_DIR / time.strftime("%Y%m%d-%H%M%S")
  for local, reason in moves:
    print_info(f"{local.name}: {reason}" + ("" if args.dry_run else f", moved to {backup}"))
    if not args.dry_run:
      backup.mkdir(parents=True, exist_ok=True)
      shutil.move(local, backup / local.name)


if __name__ == "__main__":
  main()
