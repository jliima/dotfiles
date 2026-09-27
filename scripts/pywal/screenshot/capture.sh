#!/usr/bin/env bash
# Screenshot one or more pywal-themed applications, to check how the
# current pywal theme (run pywal first) actually looks in each app.
#
# Usage: capture.sh [-o OUTDIR] [-l LANG|all] [-s WxH] [-d DELAY] [app...]
#   -o OUTDIR   where to write PNGs (default: ~/.cache/wal-screenshots)
#   -l LANG     which code snippet to show in editors: java, sh, python,
#               css, xml, or "all" to capture one shot per language
#               (default: java)
#   -s WxH      window size passed to winshot (default: 1100x700)
#   -d SECONDS  extra settle time passed to winshot (default: 1)
#   app...      one or more of: nano vim kate code konsole dolphin
#               chromium firefox obsidian spicetify claude-desktop lnav
#               qtcreator intellij obs telegram
#               (default: every app that is actually installed)
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
LANG_ARG="java"
SIZE="1100x700"
DELAY="1"
APPS=()

while getopts "o:l:s:d:h" opt; do
  case "$opt" in
    o) OUTPUT_DIR="$OPTARG" ;;
    l) LANG_ARG="$OPTARG" ;;
    s) SIZE="$OPTARG" ;;
    d) DELAY="$OPTARG" ;;
    h) grep '^#' "$0" | cut -c3-; exit 0 ;;
    *) exit 1 ;;
  esac
done
shift $((OPTIND - 1))
APPS=("$@")
[[ ${#APPS[@]} -eq 0 ]] && APPS=("${ALL_APPS[@]}")

mkdir -p "$OUTPUT_DIR"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

if [[ "$LANG_ARG" == "all" ]]; then
  LANGS=(java sh python css xml)
else
  LANGS=("$LANG_ARG")
fi

# --- per-app isolated profile builders, so screenshotting never touches
# --- or hijacks a real running instance of the app. -------------------

isolated_firefox_profile() {
  local dir="$TMP_ROOT/firefox-profile"
  mkdir -p "$dir/chrome"
  if [[ -d "$HOME/.mozilla/firefox/chrome" ]]; then
    cp -r "$HOME/.mozilla/firefox/chrome/." "$dir/chrome/"
  fi
  cat > "$dir/user.js" <<'EOF'
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
EOF
  echo "$dir"
}

isolated_vscode_profile() {
  local dir="$TMP_ROOT/vscode-data"
  mkdir -p "$dir/User"
  if [[ -f "$HOME/.config/Code/User/settings.json" ]]; then
    cp "$HOME/.config/Code/User/settings.json" "$dir/User/settings.json"
  fi
  echo "$dir"
}

obsidian_vault() {
  local dir="$TMP_ROOT/vault"
  local theme_dir="$dir/.obsidian/themes/PywalColors"
  mkdir -p "$theme_dir"
  cp "$HOME/.cache/wal/colors-obsidian.css" "$theme_dir/theme.css"
  cat > "$dir/.obsidian/appearance.json" <<'EOF'
{"cssTheme": "PywalColors"}
EOF
  cat > "$dir/Sample.md" <<'EOF'
# Pywal sample note

Some **bold**, *italic* and `inline code`, plus a [link](https://example.com).

- [ ] a checklist item
- [x] a done item

```java
// fenced code block
System.out.println("Hello, pywal!");
```
EOF
  echo "$dir"
}

# --- the actual per-app launch commands --------------------------------

capture_app() {
  local app="$1" lang="$2" outfile="$3" snippet=""
  if is_code_app "$app"; then
    snippet="$(snippet_for_lang "$lang")"
  elif is_log_app "$app"; then
    snippet="$SNIPPETS_DIR/sample-tcms.log"
  fi

  case "$app" in
    nano)
      require_cmd nano || { log_warn "  nano not installed, skipping"; return 1; }
      capture "$app ($lang)" "$SIZE" "$DELAY" "$outfile" -- \
        konsole --profile konsole-zsh -e nano "$snippet"
      ;;
    vim)
      require_cmd vim || { log_warn "  vim not installed, skipping"; return 1; }
      capture "$app ($lang)" "$SIZE" "$DELAY" "$outfile" -- \
        konsole --profile konsole-zsh -e vim -u NONE -N \
        -c "syntax on" -c "colorscheme pywal" "$snippet"
      ;;
    kate)
      require_cmd kate || { log_warn "  kate not installed, skipping"; return 1; }
      capture "$app ($lang)" "$SIZE" "$DELAY" "$outfile" -- kate -n "$snippet"
      ;;
    code)
      require_cmd code || { log_warn "  code not installed, skipping"; return 1; }
      local data_dir; data_dir="$(isolated_vscode_profile)"
      capture "$app ($lang)" "$SIZE" "$((DELAY + 2))" "$outfile" -- \
        code --user-data-dir "$data_dir" --new-window --wait "$snippet"
      ;;
    konsole)
      require_cmd konsole || { log_warn "  konsole not installed, skipping"; return 1; }
      capture "$app" "$SIZE" "$DELAY" "$outfile" -- konsole --profile konsole-zsh
      ;;
    dolphin)
      require_cmd dolphin || { log_warn "  dolphin not installed, skipping"; return 1; }
      capture "kde (dolphin)" "$SIZE" "$DELAY" "$outfile" -- dolphin "$HOME"
      ;;
    chromium)
      require_cmd chromium || { log_warn "  chromium not installed, skipping"; return 1; }
      local data_dir="$TMP_ROOT/chromium-data"
      capture "$app" "$SIZE" "$((DELAY + 2))" "$outfile" -- \
        chromium --user-data-dir="$data_dir" \
        --load-extension="$HOME/.config/chromium/pywal-theme" \
        --no-first-run --no-default-browser-check \
        --disable-search-engine-choice-screen about:blank
      ;;
    firefox)
      require_cmd firefox || { log_warn "  firefox not installed, skipping"; return 1; }
      local profile_dir; profile_dir="$(isolated_firefox_profile)"
      capture "$app" "$SIZE" "$((DELAY + 2))" "$outfile" -- \
        firefox --new-instance --profile "$profile_dir" about:blank
      ;;
    obsidian)
      require_cmd obsidian || { log_warn "  obsidian not installed, skipping"; return 1; }
      local vault; vault="$(obsidian_vault)"
      local data_dir="$TMP_ROOT/obsidian-data"
      capture "$app" "$SIZE" "$((DELAY + 2))" "$outfile" -- \
        obsidian --user-data-dir="$data_dir" "$vault"
      ;;
    spicetify)
      require_cmd spotify || { log_warn "  spotify not installed, skipping"; return 1; }
      local data_dir="$TMP_ROOT/spotify-data"
      capture "spotify (spicetify)" "$SIZE" "$((DELAY + 3))" "$outfile" -- \
        spotify --user-data-dir="$data_dir"
      ;;
    claude-desktop)
      require_cmd claude-desktop || { log_warn "  claude-desktop not installed, skipping"; return 1; }
      local data_dir="$TMP_ROOT/claude-desktop-data"
      capture "$app" "$SIZE" "$((DELAY + 2))" "$outfile" -- \
        claude-desktop --user-data-dir="$data_dir"
      ;;
    lnav)
      require_cmd lnav || { log_warn "  lnav not installed, skipping"; return 1; }
      capture "$app" "$SIZE" "$DELAY" "$outfile" -- \
        konsole --profile konsole-zsh -e lnav "$snippet"
      ;;
    qtcreator|intellij|obs|telegram)
      log_warn "  $app is not installed on this machine, skipping"
      return 1
      ;;
    *)
      log_err "  unknown app: $app"
      return 1
      ;;
  esac
}

failures=0
for app in "${APPS[@]}"; do
  log_info "Capturing $app"
  if is_code_app "$app"; then
    for lang in "${LANGS[@]}"; do
      outfile="$OUTPUT_DIR/$app-$lang.png"
      [[ ${#LANGS[@]} -eq 1 ]] && outfile="$OUTPUT_DIR/$app.png"
      capture_app "$app" "$lang" "$outfile" || ((failures++)) || true
    done
  else
    outfile="$OUTPUT_DIR/$app.png"
    capture_app "$app" "" "$outfile" || ((failures++)) || true
  fi
done

log_info "Screenshots written to $OUTPUT_DIR"
[[ "$failures" -eq 0 ]] || log_warn "$failures capture(s) failed or were skipped"
exit 0
