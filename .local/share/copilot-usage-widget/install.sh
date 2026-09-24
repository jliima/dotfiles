#!/usr/bin/env bash
# Install / refresh the Copilot Usage plasmoid from this project.
# Symlinks the package into Plasma's plasmoid dir, clears the compiled QML
# cache, and restarts plasmashell so edits to package/ actually show up.
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help]

  Install / refresh the Copilot Usage plasmoid. The widget reads its token
  from ~/.copilot/config.json.
EOF
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/com.jliima.copilotusage"

# Older versions could point the widget at a custom COPILOT_HOME via this
# marker file; it's no longer read, so clean it up.
rm -rf "$HOME/.config/copilot-usage-widget"

mkdir -p "$(dirname "$PLASMOID_DIR")"

# package/ -> plasmoids/com.jliima.copilotusage  (live = source)
rm -rf "$PLASMOID_DIR"
ln -s "$HERE/package" "$PLASMOID_DIR"

# Plasma caches *compiled* QML; without this, source edits won't load.
rm -rf "$HOME/.cache/plasmashell/qmlcache"

# Restart the shell to pick everything up.
if systemctl --user list-units --type=service 2>/dev/null | grep -q plasma-plasmashell; then
  systemctl --user restart plasma-plasmashell.service
else
  kquitapp6 plasmashell 2>/dev/null || true
  sleep 1
  (kstart plasmashell >/dev/null 2>&1 &)
fi

echo "Installed via symlink. Live install -> $HERE/package"
echo "If it's not on a panel yet: right-click panel -> Add Widgets -> 'Copilot Usage'."
