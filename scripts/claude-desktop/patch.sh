#!/usr/bin/env bash
# Installs, reverts, or reports on the claude-desktop app.asar theme patch.
#
# The patch (see asar-patch.mjs) makes the app insertCSS() an external,
# user-writable theme file (~/.config/claude-desktop-theme/theme.css) into
# every page it loads. This script owns the root side of that: keeping a
# pristine backup of app.asar before ever touching it, re-baselining that
# backup whenever apt has replaced app.asar with a newer version, and making a
# bad patch trivially reversible. Only the copies into /usr/lib run as root;
# the patched file is built as you, so node from nvm works too.
#
# Themer runs `ensure` after writing ~/.config/claude-desktop-theme/theme.css. Every apt upgrade of claude-desktop
# replaces app.asar with an unpatched copy, so `ensure` checks the patch and reinstalls it when missing.
#
# Usage:
#   patch.sh install   # (re)patch, safe to run repeatedly
#   patch.sh revert    # restore the pristine app.asar
#   patch.sh status    # report current state, no changes
#   patch.sh check     # exit 0 if the installed version is patched, no sudo
#   patch.sh ensure    # check, and install when missing (asks for the password through polkit when there is no tty)
#
# Needs: node (also found through nvm), sudo or pkexec. A backup left by an earlier version of this patch
# (app.asar.*-orig) must be renamed to app.asar.themer-orig, with its .version file, once; install explains it.
set -euo pipefail

RESOURCES_DIR="/usr/lib/claude-desktop/resources"
ASAR="$RESOURCES_DIR/app.asar"
BACKUP="$RESOURCES_DIR/app.asar.themer-orig"
VERSION_FILE="$BACKUP.version"
# Present in app.asar only once it is patched (the theme file the patch reads).
MARKER="claude-desktop-theme"
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
PATCHER="$SCRIPT_DIR/asar-patch.mjs"

installed_version() {
  dpkg-query -W -f='${Version}' claude-desktop 2>/dev/null || echo "unknown"
}

backup_version() {
  [[ -f "$VERSION_FILE" ]] && cat "$VERSION_FILE" || echo ""
}

# Runs a command as root: directly when already root, with sudo on a terminal or when sudo needs no password, else
# through pkexec (a graphical password prompt), so Themer can ask when it runs from a keyboard shortcut.
as_root() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
  elif [[ -t 0 ]] || sudo -n true 2>/dev/null; then
    sudo "$@"
  elif [[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]] && command -v pkexec >/dev/null; then
    pkexec "$@"
  else
    echo "Error: cannot ask for a password here. Run in a terminal: $0 install" >&2
    return 1
  fi
}

# node for building the patch; nvm is often loaded lazily by the shell profile, so source it when node is missing.
find_node() {
  if ! command -v node >/dev/null && [[ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]]; then
    # shellcheck disable=SC1091
    . "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
  fi
  command -v node >/dev/null
}

# Patched for the installed version: the backup was taken from this version and app.asar differs from it.
is_patched() {
  [[ -f "$BACKUP" && "$(backup_version)" == "$(installed_version)" ]] && ! cmp -s "$ASAR" "$BACKUP"
}

require_asar() {
  if [[ ! -f "$ASAR" ]]; then
    echo "Error: $ASAR not found. Is claude-desktop installed?" >&2
    exit 1
  fi
}

cmd_status() {
  require_asar
  echo "installed claude-desktop version: $(installed_version)"
  if [[ -f "$BACKUP" ]]; then
    echo "pristine backup:                  $BACKUP (from version $(backup_version))"
    if cmp -s "$ASAR" "$BACKUP"; then
      echo "current app.asar:                 pristine (patch not applied)"
    else
      echo "current app.asar:                 differs from backup (patched, or manually changed)"
    fi
  else
    echo "pristine backup:                  none yet (patch never installed)"
  fi
}

cmd_check() {
  require_asar
  if is_patched; then
    echo "patched ($(installed_version))"
  else
    echo "not patched for installed version $(installed_version)"
    exit 1
  fi
}

cmd_revert() {
  require_asar
  if [[ ! -f "$BACKUP" ]]; then
    echo "Error: no backup at $BACKUP, nothing to revert." >&2
    exit 1
  fi
  echo "Restoring pristine app.asar from backup..."
  as_root cp "$BACKUP" "$ASAR"
  echo "Done. Restart claude-desktop to pick it up."
}

cmd_install() {
  require_asar
  if ! find_node; then
    echo "Error: node is required to build the patch." >&2
    exit 1
  fi
  if [[ $EUID -eq 0 ]]; then
    echo "Error: run this as your own user; it asks for root only where it must." >&2
    exit 1
  fi

  local current_version backed_up_version
  current_version="$(installed_version)"
  backed_up_version="$(backup_version)"

  if [[ ! -f "$BACKUP" || "$backed_up_version" != "$current_version" ]]; then
    if grep -qa "$MARKER" "$ASAR"; then
      echo "Error: app.asar is already patched but there is no pristine backup for version $current_version." >&2
      echo "If an earlier patch left a backup (ls $RESOURCES_DIR/app.asar.*-orig), rename it and its .version file" >&2
      echo "to app.asar.themer-orig and app.asar.themer-orig.version with sudo mv; otherwise run:" >&2
      echo "sudo apt reinstall claude-desktop" >&2
      exit 1
    fi
    if [[ -f "$BACKUP" ]]; then
      echo "claude-desktop was updated ($backed_up_version -> $current_version)."
      echo "The installed app.asar is a fresh, unpatched copy from that update; re-baselining the backup from it."
    else
      echo "No backup yet; backing up the installed app.asar as the pristine copy."
    fi
    local tmp_version
    tmp_version="$(mktemp)"
    echo "$current_version" > "$tmp_version"
    as_root cp "$ASAR" "$BACKUP"
    # mktemp files are 0600; check reads the version as a normal user, so install it world-readable.
    as_root install -m 644 "$tmp_version" "$VERSION_FILE"
    rm -f "$tmp_version"
  else
    echo "Backup already matches installed version $current_version; patching from it."
  fi

  local tmp_out
  tmp_out="$(mktemp --suffix=.asar)"
  # Expand now: tmp_out is local and gone by the time the EXIT trap runs.
  trap "rm -f '$tmp_out'" EXIT

  echo "Building patched asar from the pristine backup..."
  node "$PATCHER" "$BACKUP" "$tmp_out"

  echo "Installing patched asar..."
  as_root cp "$tmp_out" "$ASAR"
  echo ""
  echo "Installed. Restart claude-desktop to pick it up."
  echo "If anything looks broken, run: $0 revert"
}

notify() {
  command -v notify-send >/dev/null && notify-send -a themer -i claude-desktop "Claude theme" "$1" || true
}

cmd_ensure() {
  if ! dpkg-query -W claude-desktop >/dev/null 2>&1; then
    echo "claude-desktop is not installed, skipping the app.asar patch."
    exit 0
  fi

  require_asar
  if is_patched; then
    echo "Reload the Claude window (Ctrl+R) or restart the app to see the new theme."
    exit 0
  fi

  echo "Installing the app.asar theme patch..."
  if ! cmd_install; then
    notify "app.asar is not patched. Run $0 install in a terminal"
    exit 1
  fi

  notify "Theme patch installed. Restart Claude to apply it."
}

case "${1:-install}" in
  install) cmd_install ;;
  ensure) cmd_ensure ;;
  revert) cmd_revert ;;
  status) cmd_status ;;
  check) cmd_check ;;
  *)
    echo "usage: $0 {install|revert|status|check|ensure}" >&2
    exit 2
    ;;
esac
