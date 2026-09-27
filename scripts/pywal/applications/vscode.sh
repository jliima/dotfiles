#!/usr/bin/env bash
# VSCode pywal theme application script.
# Merges rendered per-language token colors into the user's settings.json
# (editor.tokenColorCustomizations) without touching any other settings.
set -euo pipefail

CACHE_DIR="$HOME/.cache/wal"
SOURCE_FILE="$CACHE_DIR/colors-vscode-tokens.json"
SETTINGS_DIR="$HOME/.config/Code/User"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "Error: $SOURCE_FILE not found. Run pywal first." >&2
  exit 1
fi

if [[ ! -d "$SETTINGS_DIR" ]]; then
  echo "VSCode user settings directory not found at $SETTINGS_DIR; skipping." >&2
  exit 0
fi

mkdir -p "$SETTINGS_DIR"
[[ -f "$SETTINGS_FILE" ]] || echo '{}' > "$SETTINGS_FILE"

python3 - "$SOURCE_FILE" "$SETTINGS_FILE" <<'EOF'
import json
import sys

tokens_path, settings_path = sys.argv[1], sys.argv[2]

with open(tokens_path) as f:
    tokens = json.load(f)

def clean_jsonc(text):
    # Strip // line comments and trailing commas before } or ], both only
    # when outside string literals (VSCode's settings.json tolerates both,
    # plain json.loads tolerates neither).
    out = []
    in_string = False
    escaped = False
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        if in_string:
            out.append(c)
            if escaped:
                escaped = False
            elif c == "\\":
                escaped = True
            elif c == '"':
                in_string = False
            i += 1
            continue
        if c == '"':
            in_string = True
            out.append(c)
            i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if c == ",":
            j = i + 1
            while j < n and text[j] in " \t\r\n":
                j += 1
            if j < n and text[j] in "}]":
                i += 1
                continue
        out.append(c)
        i += 1
    return "".join(out)

with open(settings_path) as f:
    text = f.read()
settings = json.loads(clean_jsonc(text)) if text.strip() else {}

settings["editor.tokenColorCustomizations"] = tokens

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

print(f"Merged editor.tokenColorCustomizations into {settings_path}")
EOF
