#!/usr/bin/env bash
# IntelliJ pywal theme application script.
# Deploys the pywal-generated color scheme and UI theme to all installed JetBrains IDEs.
#
# Called by: python3 ~/dotfiles/scripts/pywal/run-pywal.py --app intellij
# Requires:  jar (JDK), wal (pywal)
set -euo pipefail

CACHE_DIR="$HOME/.cache/wal"
CONFIG_DIR="$HOME/.config/JetBrains"
SHARE_DIR="$HOME/.local/share/JetBrains"
PROJECT_DIR="$HOME/JetBrainsProjects/jetbrains-pywal-theme"
ASSETS_DIR="$PROJECT_DIR/assets"

ICLS_CACHE="$CACHE_DIR/colors-intellij.icls"
THEME_JSON_CACHE="$CACHE_DIR/colors-intellij-theme.json"

SCHEME_NAME="pywal-color-scheme"
JAR_NAME="pywal-theme.jar"
JAR_SUBDIR="pywal"
THEME_JSON_NAME="pywal.theme.json"

# ── Validate cache files ─────────────────────────────────────────────────────
if [[ ! -f "$ICLS_CACHE" ]]; then
  echo "Error: $ICLS_CACHE not found. Run pywal first." >&2
  exit 1
fi

if [[ ! -f "$THEME_JSON_CACHE" ]]; then
  echo "Error: $THEME_JSON_CACHE not found. Run pywal first." >&2
  exit 1
fi

# ── Build processed ICLS (strip # from hex color values) ─────────────────────
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

PROCESSED_ICLS="$BUILD_DIR/${SCHEME_NAME}.icls"
sed 's/value="#\([0-9a-fA-F]\{6\}\)"/value="\1"/g' "$ICLS_CACHE" > "$PROCESSED_ICLS"
echo "✓ Processed ICLS (stripped # from hex values)"

# ── Deploy ICLS to all IDE config directories ─────────────────────────────────
deployed_icls=0
while IFS= read -r -d '' colors_dir; do
  if cp "$PROCESSED_ICLS" "$colors_dir/${SCHEME_NAME}.icls"; then
    echo "  → $colors_dir/${SCHEME_NAME}.icls"
    ((deployed_icls++)) || true
  fi
done < <(find "$CONFIG_DIR" -maxdepth 2 -type d -name "colors" -print0 2>/dev/null)

echo "✓ Deployed ICLS to $deployed_icls IDE config directories"

# ── Build theme JAR ───────────────────────────────────────────────────────────
JAR_BUILD_DIR="$BUILD_DIR/jar"
mkdir -p "$JAR_BUILD_DIR/META-INF" "$JAR_BUILD_DIR/theme"

# Copy static assets
cp "$ASSETS_DIR/META-INF/MANIFEST.MF" "$JAR_BUILD_DIR/META-INF/"
cp "$ASSETS_DIR/META-INF/plugin.xml"  "$JAR_BUILD_DIR/META-INF/"
cp "$ASSETS_DIR/META-INF/pluginIcon.svg" "$JAR_BUILD_DIR/META-INF/"

# Copy the pywal-generated theme JSON (no # stripping needed for JSON)
cp "$THEME_JSON_CACHE" "$JAR_BUILD_DIR/theme/$THEME_JSON_NAME"

# Bundle the processed ICLS inside the JAR as fallback
cp "$PROCESSED_ICLS" "$JAR_BUILD_DIR/theme/${SCHEME_NAME}.icls"

# Package the JAR
JAR_OUTPUT="$BUILD_DIR/$JAR_NAME"
(cd "$JAR_BUILD_DIR" && jar cf "$JAR_OUTPUT" META-INF theme)
echo "✓ Built $JAR_NAME"

# ── Deploy JAR to all IDE share directories ───────────────────────────────────
deployed_jar=0
while IFS= read -r ide_dir; do
  target_dir="$ide_dir/$JAR_SUBDIR"
  mkdir -p "$target_dir"
  if cp "$JAR_OUTPUT" "$target_dir/$JAR_NAME"; then
    echo "  → $target_dir/$JAR_NAME"
    ((deployed_jar++)) || true
  fi
done < <(find "$SHARE_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | \
  grep -E '/(IntelliJIdea|PyCharm|WebStorm|Rider|DataGrip|GoLand|CLion|PhpStorm|RubyMine|AppCode|Android)[0-9]')

echo "✓ Deployed JAR to $deployed_jar IDE share directories"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "IntelliJ pywal theme applied."
echo "  Color scheme: $SCHEME_NAME"
echo "  IDEs updated: ICLS=$deployed_icls, JAR=$deployed_jar"
echo ""
echo "Note: Restart IntelliJ IDEs to pick up the new UI theme."
echo "      The color scheme may update without restart in some versions."
