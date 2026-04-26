#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Name:        set-monitor-layout.py
# Description: Set the dual-monitor layout via kscreen-doctor.
#
# Details:
#   Configures the position and rotation of the primary and secondary monitors
#   using kscreen-doctor. The secondary monitor can be placed to the left or
#   right of the primary, in landscape or portrait orientation. The TV output
#   is always disabled.
#
#   Available layouts:
#     left-landscape  (default) - secondary left, both landscape
#     left-portrait             - secondary left in portrait, primary landscape
#     right-landscape           - secondary right, both landscape
#     right-portrait            - secondary right in portrait, primary landscape
# ------------------------------------------------------------------------------

import argparse
import subprocess
import sys

# ==== Configuration ====
PRIMARY = "DP-1"
SECONDARY = "DP-2"
TV = "HDMI-A-1"

# Layout definitions: (primary_position, secondary_position, primary_rotation, secondary_rotation)
LAYOUTS = {
  "left-landscape": {
    "primary_position": "2560,0",
    "secondary_position": "0,0",
    "primary_rotation": "normal",
    "secondary_rotation": "normal",
  },
  "left-portrait": {
    "primary_position": "1440,560",
    "secondary_position": "0,0",
    "primary_rotation": "normal",
    "secondary_rotation": "left",
  },
  "right-landscape": {
    "primary_position": "0,0",
    "secondary_position": "2560,0",
    "primary_rotation": "normal",
    "secondary_rotation": "normal",
  },
  "right-portrait": {
    "primary_position": "0,1120",
    "secondary_position": "2560,0",
    "primary_rotation": "normal",
    "secondary_rotation": "left",
  },
}

DEFAULT_LAYOUT = "left-landscape"


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
def create_parser() -> argparse.ArgumentParser:
  """Create the argument parser."""
  layout_names = ", ".join(LAYOUTS.keys())
  parser = argparse.ArgumentParser(
    description="Set the dual-monitor layout via kscreen-doctor.",
    epilog=f"Available layouts: {layout_names}\nDefault: {DEFAULT_LAYOUT}",
    formatter_class=argparse.RawDescriptionHelpFormatter,
  )
  parser.add_argument(
    "layout",
    nargs="?",
    default=DEFAULT_LAYOUT,
    choices=LAYOUTS.keys(),
    help=f"Layout to apply (default: {DEFAULT_LAYOUT}).",
  )
  parser.add_argument(
    "-l", "--list",
    action="store_true",
    help="List available layouts and exit.",
  )
  return parser


def list_layouts() -> None:
  """Print all available layouts."""
  print_header("Available layouts")
  for name, cfg in LAYOUTS.items():
    default_tag = " (default)" if name == DEFAULT_LAYOUT else ""
    print_info(f"{name}{default_tag}")
    print(f"    Primary:   {PRIMARY} at {cfg['primary_position']}  rotation={cfg['primary_rotation']}")
    print(f"    Secondary: {SECONDARY} at {cfg['secondary_position']}  rotation={cfg['secondary_rotation']}")


def apply_layout(name: str) -> int:
  """Apply the specified monitor layout.

  Returns:
    0 on success, 1 on failure.
  """
  cfg = LAYOUTS[name]

  cmd = [
    "kscreen-doctor",
    f"output.{PRIMARY}.enable",
    f"output.{PRIMARY}.primary",
    f"output.{SECONDARY}.enable",
    f"output.{TV}.disable",
    f"output.{PRIMARY}.position.{cfg['primary_position']}",
    f"output.{SECONDARY}.position.{cfg['secondary_position']}",
    f"output.{PRIMARY}.rotation.{cfg['primary_rotation']}",
    f"output.{SECONDARY}.rotation.{cfg['secondary_rotation']}",
  ]

  print_info(f"Primary:   {PRIMARY} at {cfg['primary_position']}  rotation={cfg['primary_rotation']}")
  print_info(f"Secondary: {SECONDARY} at {cfg['secondary_position']}  rotation={cfg['secondary_rotation']}")
  print_info(f"TV:        {TV} disabled")

  result = subprocess.run(cmd, check=False)
  if result.returncode != 0:
    print_error(f"kscreen-doctor exited with code {result.returncode}")
    return 1

  return 0


def main() -> int:
  """Main entry point."""
  parser = create_parser()
  args = parser.parse_args()

  if args.list:
    list_layouts()
    return 0

  print_header(f"Applying layout: {args.layout}")
  return apply_layout(args.layout)


if __name__ == "__main__":
  sys.exit(main())
