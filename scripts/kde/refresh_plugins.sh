#!/bin/bash
# ------------------------------------------------------------------------------
# Name:        refresh_plugins.sh
# Description: Rebuild and install every custom KDE plugin, re-apply the current
#              Themer theme and refresh Plasma. Run after a Plasma/KDE upgrade.
#
# Details:
#   Builds, in order: every repo in $KDE_REPOS (default ~/Git/KDE) through its
#   install.sh, the Themer KWin decoration (decoration/build.sh of the Themer
#   clone `themer` runs from) and the themed Okular Markdown backend
#   ($OKULAR_MARKDOWN, default ~/Git/okular-markdown). The installers only
#   write plugin files under ~/.local; any KDE config file (~/.config/*rc, env, systemd)
#   a build changed is listed. Then `themer apply --force` with the theme and
#   variant `themer current` prints, so the settings are rewritten with the
#   values they already have, and plasmashell restarts with a clean QML cache.
#   A failed build is reported and the rest still run; the exit code is 1.
# ------------------------------------------------------------------------------
set -uo pipefail

# ==== Configuration ====
KDE_REPOS="${KDE_REPOS:-$HOME/Git/KDE}"
OKULAR_MARKDOWN="${OKULAR_MARKDOWN:-$HOME/Git/okular-markdown}"
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/refresh-plugins"

# ==== Colors ====
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
BOLD='\033[1m'
NC='\033[0m'

# ==== Output helpers ====
print_header() { echo -e "${BOLD}${MAGENTA}>>> $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${BLUE}> $1${NC}"; }
print_warn() { echo -e "${YELLOW}! $1${NC}"; }

failed=0

# Runs a build script from its own folder, output to a log shown only on failure.
build() {
  local name="$1" script="$2"
  local log="${LOG_DIR}/${name}.log"
  if [[ ! -x "${script}" ]]; then
    print_warn "${name}: ${script} not found, skipped"
    return
  fi
  if (cd "$(dirname "${script}")" && "./$(basename "${script}")") >"${log}" 2>&1 </dev/null; then
    print_success "${name}"
  else
    print_error "${name} failed, log: ${log}"
    tail -n 20 "${log}"
    failed=1
  fi
}

main() {
  if [[ $# -gt 0 ]]; then
    echo "Usage: $(basename "$0")   (no options; KDE_REPOS and OKULAR_MARKDOWN override the repo paths)"
    exit 0
  fi
  local theme variant themer_dir sums
  read -r theme variant < <(themer current) || { print_error "themer current failed"; exit 1; }
  themer_dir="$(dirname "$(readlink -f "$(command -v themer)")")"
  mkdir -p "${LOG_DIR}"
  # Content snapshot of the KDE config files, checked after the builds
  sums="${LOG_DIR}/config.md5"
  (cd "$HOME/.config" && find . -maxdepth 1 -name '*rc' -xtype f -o -path './environment.d/*' -xtype f \
    -o -path './plasma-workspace/env/*' -xtype f -o -path './systemd/user/*' -xtype f | xargs -d '\n' md5sum) >"${sums}"

  print_header "Building plugins (logs in ${LOG_DIR})"
  local repo
  for repo in "${KDE_REPOS}"/*/; do
    build "$(basename "${repo}")" "${repo}install.sh"
  done
  build "themer-decoration" "${themer_dir}/decoration/build.sh"
  build "okular-markdown" "${OKULAR_MARKDOWN}/build.sh"

  local changed
  changed="$(cd "$HOME/.config" && md5sum -c --quiet "${sums}" 2>/dev/null | sed 's/: FAILED$//')"
  if [[ -n "${changed}" ]]; then
    print_warn "Config files the builds changed (in ~/.config):"
    echo "${changed}" | sed 's/^/  /'
  else
    print_success "No KDE config file changed by the builds"
  fi

  print_header "Applying Themer theme ${theme} ${variant}"
  themer apply -t "${theme}" -v "${variant}" --force >"${LOG_DIR}/themer.log" 2>&1 \
    && print_success "themer apply" \
    || { print_error "themer apply failed, log: ${LOG_DIR}/themer.log"; failed=1; }

  print_header "Refreshing Plasma"
  rm -rf "$HOME/.cache/plasmashell/qmlcache" "$HOME/.cache/icon-cache.kcache"
  qdbus6 org.kde.KWin /KWin reconfigure
  systemctl --user reset-failed plasma-plasmashell.service
  systemctl --user restart plasma-plasmashell.service \
    && print_success "plasmashell restarted" \
    || { print_error "plasmashell restart failed"; failed=1; }
  # krunner loads its runners and the tab-nav patch only at start
  systemctl --user is-active -q plasma-krunner.service && systemctl --user restart plasma-krunner.service \
    && print_success "krunner restarted"

  exit "${failed}"
}

main "$@"
