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
JAR_SUBDIR="pywal/lib"
THEME_JSON_NAME="pywal.theme.json"
RELOAD_PLUGIN_JAR="$PROJECT_DIR/reload-plugin/build/distributions/pywal-reload-plugin-1.0.0.zip"
RELOAD_PLUGIN_SUBDIR="pywal-reload-plugin/lib"
RELOAD_PORT=9988

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

# ── Deploy reload plugin to all IDE share directories ────────────────────────
if [[ -f "$RELOAD_PLUGIN_JAR" ]]; then
  RELOAD_PLUGIN_TMP="$BUILD_DIR/reload-plugin-unzip"
  unzip -q "$RELOAD_PLUGIN_JAR" -d "$RELOAD_PLUGIN_TMP"
  RELOAD_PLUGIN_INNER_JAR=$(find "$RELOAD_PLUGIN_TMP" -name "*.jar" | head -1)

  deployed_reload=0
  while IFS= read -r ide_dir; do
    target_dir="$ide_dir/$RELOAD_PLUGIN_SUBDIR"
    mkdir -p "$target_dir"
    if cp "$RELOAD_PLUGIN_INNER_JAR" "$target_dir/"; then
      echo "  → $target_dir/$(basename "$RELOAD_PLUGIN_INNER_JAR")"
      ((deployed_reload++)) || true
    fi
  done < <(find "$SHARE_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | \
    grep -E '/(IntelliJIdea|PyCharm|WebStorm|Rider|DataGrip|GoLand|CLion|PhpStorm|RubyMine|AppCode|Android)[0-9]')

  echo "✓ Deployed reload plugin to $deployed_reload IDE share directories"
else
  echo "⚠ Reload plugin not built; skipping (run 'cd $PROJECT_DIR/reload-plugin && ./gradlew buildPlugin')"
fi

# ── Trigger live reload in any running IDE instances ─────────────────────────
reload_response=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  "http://localhost:$RELOAD_PORT/reload" --max-time 3 2>/dev/null || true)

if [[ "$reload_response" == "200" ]]; then
  echo "✓ Live reload triggered (port $RELOAD_PORT)"
else
  echo "  (No running IDE responded on port $RELOAD_PORT — restart to apply)"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "IntelliJ pywal theme applied."
echo "  Color scheme: $SCHEME_NAME"
echo "  IDEs updated: ICLS=$deployed_icls, JAR=$deployed_jar"
