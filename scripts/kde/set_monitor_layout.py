#!/usr/bin/env python3
"""Sets the dual-monitor layout via kscreen-doctor.

Configures the position and rotation of the primary and secondary monitors using kscreen-doctor. The secondary
monitor can be placed to the left or right of the primary, in landscape or portrait orientation. The TV output is
always disabled.

Available layouts:
    left-landscape  (default) - secondary left, both landscape
    left-portrait             - secondary left in portrait, primary landscape
    right-landscape           - secondary right, both landscape
    right-portrait            - secondary right in portrait, primary landscape
"""

import argparse
import pathlib
import subprocess
import sys

# The helpers package sits next to the script folders, which are not on the import path.
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
from helpers import log  # pylint: disable=wrong-import-position

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


def create_parser() -> argparse.ArgumentParser:
    """Creates the argument parser."""
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
        "-l",
        "--list",
        action="store_true",
        help="List available layouts and exit.",
    )
    return parser


def list_layouts() -> None:
    """Prints all available layouts."""
    log.header("Available layouts")
    for name, cfg in LAYOUTS.items():
        default_tag = " (default)" if name == DEFAULT_LAYOUT else ""
        log.info(f"{name}{default_tag}")
        with log.indent():
            log.plain(f"Primary:   {PRIMARY} at {cfg['primary_position']}  rotation={cfg['primary_rotation']}")
            log.plain(f"Secondary: {SECONDARY} at {cfg['secondary_position']}  rotation={cfg['secondary_rotation']}")


def apply_layout(name: str) -> int:
    """Applies the specified monitor layout.

    Args:
        name: A key of LAYOUTS.

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

    log.info(f"Primary:   {PRIMARY} at {cfg['primary_position']}  rotation={cfg['primary_rotation']}")
    log.info(f"Secondary: {SECONDARY} at {cfg['secondary_position']}  rotation={cfg['secondary_rotation']}")
    log.info(f"TV:        {TV} disabled")

    result = subprocess.run(cmd, check=False)
    if result.returncode != 0:
        log.error(f"kscreen-doctor exited with code {result.returncode}")
        return 1

    return 0


def main() -> int:
    """Parses the arguments and applies or lists layouts."""
    parser = create_parser()
    args = parser.parse_args()

    if args.list:
        list_layouts()
        return 0

    log.header(f"Applying layout: {args.layout}")
    return apply_layout(args.layout)


if __name__ == "__main__":
    sys.exit(main())
