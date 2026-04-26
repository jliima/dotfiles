#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Name:        display-colors-cli.py
# Description: Display a pywal color palette JSON file in the terminal.
#
# Details:
#   Renders truecolor swatches for all special colors (including custom ones),
#   and the standard 16-color palette. If no file is given, displays the
#   currently active pywal theme (detected via "wal --theme").
#
# Dependencies: (none — stdlib only)
# ------------------------------------------------------------------------------

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

# ==== Configuration ====
COLORSCHEMES_DIR = Path.home() / ".config/wal/colorschemes"
SWATCH_W = 8
SHADE_LEVELS = [1, 2, 3, 4, 5]


# ==== Colors ====
class Colors:
  """ANSI color codes for terminal output."""
  RESET = "\033[0m"
  BOLD = "\033[1m"
  RED = "\033[91m"
  GREEN = "\033[92m"
  YELLOW = "\033[93m"
  BLUE = "\033[94m"
  MAGENTA = "\033[95m"
  CYAN = "\033[96m"


# ==== Output helpers ====
def print_header(message: str) -> None:
  """Print a section header."""
  print(f"{Colors.BOLD}{Colors.MAGENTA}>>> {message}{Colors.RESET}")


def print_success(message: str) -> None:
  """Print a success message."""
  print(f"{Colors.GREEN}✓ {message}{Colors.RESET}")


def print_error(message: str) -> None:
  """Print an error message."""
  print(f"{Colors.RED}✗ {message}{Colors.RESET}", file=sys.stderr)


def print_info(message: str) -> None:
  """Print an informational message."""
  print(f"{Colors.BLUE}> {message}{Colors.RESET}")


def print_warn(message: str) -> None:
  """Print a warning message."""
  print(f"{Colors.YELLOW}! {message}{Colors.RESET}", file=sys.stderr)


# ==== Functions ====
def hex_to_rgb(hex_color: str) -> tuple[int, int, int]:
  """Convert a hex color string to an (r, g, b) tuple."""
  h = hex_color.lstrip("#")
  return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def swatch(hex_color: str, width: int = SWATCH_W) -> str:
  """Render a colored block using truecolor escape sequences."""
  r, g, b = hex_to_rgb(hex_color)
  return f"\033[48;2;{r};{g};{b}m{' ' * width}\033[0m"


def dim(text: str) -> str:
  """Wrap text in dim ANSI formatting."""
  return f"\033[2m{text}\033[0m"


def bold(text: str) -> str:
  """Wrap text in bold ANSI formatting."""
  return f"\033[1m{text}\033[0m"


def visible_len(s: str) -> int:
  """Return the visible length of a string (ignoring ANSI escapes)."""
  return len(re.sub(r"\033\[[0-9;]*m", "", s))


def pad_visible(s: str, width: int) -> str:
  """Pad a string to a visible width, accounting for ANSI escapes."""
  return s + " " * max(0, width - visible_len(s))


def section_header(title: str) -> None:
  """Print a section divider."""
  line = f"  ── {title} "
  print()
  print(bold(line + "─" * max(0, 78 - len(line))))
  print()


def color_line(label: str, hex_val: str, label_w: int = 20) -> str:
  """Format a single color entry line."""
  r, g, b = hex_to_rgb(hex_val)
  return f"  {label:<{label_w}} {swatch(hex_val)}  {hex_val}  rgb({r:>3}, {g:>3}, {b:>3})"


def detect_last_theme() -> Path | None:
  """Detect the last-used pywal theme by parsing 'wal --theme' output."""
  try:
    result = subprocess.run(
      ["wal", "--theme"],
      capture_output=True, text=True, check=False,
    )
  except FileNotFoundError:
    print_error("'wal' command not found. Is pywal installed?")
    return None

  for line in result.stdout.splitlines():
    if "(last used)" in line:
      # Lines look like: " - parecolors (last used)"
      match = re.search(r"^\s*-\s+(.+?)\s+\(last used\)", line)
      if match:
        theme_name = match.group(1).strip()
        print_info(f"Detected last-used theme: {theme_name}")
        return find_theme_file(theme_name)

  print_error("Could not detect the last-used theme from 'wal --theme' output.")
  return None


def find_theme_file(name: str) -> Path | None:
  """Locate a theme JSON file by name in the colorschemes directory."""
  filename = name if name.endswith(".json") else f"{name}.json"

  for subdir in ("dark", "light"):
    candidate = COLORSCHEMES_DIR / subdir / filename
    if candidate.exists():
      return candidate

  # Also try as a direct path
  direct = Path(name).expanduser()
  if direct.exists():
    return direct

  print_error(f"Theme file not found: {filename}")
  return None


def classify_special_keys(special: dict) -> tuple[dict[str, str], list[str]]:
  """Split special keys into pywal-standard entries and custom keys.

  Returns:
    Tuple of (standalone, custom_keys).
    - standalone: pywal-recognized keys (background, foreground, cursor)
    - custom_keys: all remaining keys in their original JSON order
  """
  standalone_names = {"background", "foreground", "cursor"}

  standalone: dict[str, str] = {}
  custom_keys: list[str] = []

  for key in special:
    if key in standalone_names:
      standalone[key] = special[key]
    else:
      custom_keys.append(key)

  return standalone, custom_keys


def display_standalone(standalone: dict[str, str]) -> None:
  """Display standalone special colors (background, foreground, cursor)."""
  for key in ("background", "foreground", "cursor"):
    if key in standalone:
      print(color_line(key, standalone[key]))


def display_custom(special: dict, custom_keys: list[str]) -> None:
  """Display custom special colors, preserving JSON order.

  Shade families (e.g. black1-5) are rendered as compact swatch rows.
  All other keys are rendered as individual color lines.
  """
  if not custom_keys:
    return

  section_header("Custom")

  family_pattern = re.compile(r"^([a-zA-Z]+?)(\d+)$")

  # Pre-scan to identify which prefixes form shade families
  family_members: dict[str, list[tuple[int, str]]] = {}
  for key in custom_keys:
    match = family_pattern.match(key)
    if match:
      family_members.setdefault(match.group(1), []).append((int(match.group(2)), key))

  # Only treat as a family if there are 2+ shades
  families = {name for name, members in family_members.items() if len(members) >= 2}
  rendered_families: set[str] = set()
  label_w = 12
  swatch_col_w = 10
  hex_sep = "   "

  for key in custom_keys:
    match = family_pattern.match(key)
    if match and match.group(1) in families:
      family_name = match.group(1)
      if family_name in rendered_families:
        continue
      rendered_families.add(family_name)

      shades = sorted(family_members[family_name])
      row = f"  {family_name:<{label_w}}"
      for _, shade_key in shades:
        row += swatch(special[shade_key], width=swatch_col_w)
      print(row)

      hex_row = " " * (label_w + 2)
      hex_parts = [f"{special[sk]:>7}" for _, sk in shades]
      print(dim(hex_row + hex_sep.join(hex_parts)))
    else:
      print(color_line(key, special[key], label_w=24))

  print()


def display_special(special: dict) -> None:
  """Display all special colors."""
  section_header("Special")

  standalone, custom_keys = classify_special_keys(special)

  display_standalone(standalone)
  display_custom(special, custom_keys)


def display_colors(colors: dict) -> None:
  """Display the standard 16-color palette."""
  section_header("Colors")

  col_visible_w = 46

  for i in range(8):
    parts = []
    for offset in (0, 8):
      key = f"color{i + offset}"
      val = colors.get(key)
      if val:
        parts.append(color_line(key, val, label_w=8))

    if len(parts) == 2:
      print(f"{pad_visible(parts[0], col_visible_w)}  {parts[1]}")
    elif parts:
      print(parts[0])

  print()


def create_parser() -> argparse.ArgumentParser:
  """Create the argument parser."""
  parser = argparse.ArgumentParser(
    description="Display a pywal color palette in the terminal with truecolor swatches.",
    formatter_class=argparse.RawDescriptionHelpFormatter,
  )
  parser.add_argument(
    "palette",
    nargs="?",
    default=None,
    help="Path to a palette JSON file. If omitted, displays the currently active theme.",
  )
  return parser


def main() -> int:
  """Main entry point."""
  parser = create_parser()
  args = parser.parse_args()

  if args.palette:
    path = Path(args.palette)
  else:
    path = detect_last_theme()
    if not path:
      return 1

  print_header(f"Theme: {path.stem}")

  try:
    with open(path) as f:
      data = json.load(f)
  except FileNotFoundError:
    print_error(f"File not found: {path}")
    return 1
  except json.JSONDecodeError as e:
    print_error(f"Invalid JSON: {e}")
    return 1

  if "special" in data:
    display_special(data["special"])
  if "colors" in data:
    display_colors(data["colors"])

  return 0


if __name__ == "__main__":
  sys.exit(main())
