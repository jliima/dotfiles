"""Colored, indented status output for scripts.

Usage:
    from helpers import log

    log.header('Mounting vault')
    log.info('Unlocking dataset')
    with log.indent():
        log.success('Dataset unlocked')
    log.warn('Stash is not running')
    log.error('Mount failed')

The shell counterpart is helpers/log.sh and prints the same markers.
Colors are dropped when the stream is not a terminal or NO_COLOR is set; FORCE_COLOR keeps them.
log.set_timestamps(True) puts [HH:MM:SS] in front of every line, for long runs whose output is tee'd or redirected.
"""

from __future__ import annotations

import contextlib
import os
import sys
import time
from collections.abc import Iterator
from typing import NoReturn
from typing import TextIO

INDENT_WIDTH = 2

RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
MAGENTA = "\033[95m"
CYAN = "\033[96m"
WHITE = "\033[97m"

# Printing happens from many functions, so the indent level is module state instead of a logger passed around.
_indent_level = 0  # pylint: disable=invalid-name
_quiet = False  # pylint: disable=invalid-name
_timestamps = False  # pylint: disable=invalid-name
_stderr_only = False  # pylint: disable=invalid-name
_status_stream: TextIO | None = None  # pylint: disable=invalid-name  # Stream with an unfinished status line.


def use_color(stream: TextIO) -> bool:
    """Returns whether ANSI colors should be written to the stream."""
    if "NO_COLOR" in os.environ:
        return False
    return "FORCE_COLOR" in os.environ or stream.isatty()


def c(code: str, stream: TextIO = sys.stdout) -> str:
    """Returns the ANSI code itself, or an empty string when the stream does not support color.

    For inline styling inside messages: BOLD = log.c(log.BOLD), then f"{BOLD}text{RESET}".
    """
    return code if use_color(stream) else ""


def colorize(text: str, *codes: str, stream: TextIO = sys.stdout) -> str:
    """Wraps text in the given ANSI codes when the stream supports color."""
    if not codes or not use_color(stream):
        return text
    return f"{''.join(codes)}{text}{RESET}"


def _emit(message: str, marker: str, codes: tuple[str, ...], stream: TextIO, quietable: bool = False) -> None:
    if quietable and _quiet:
        return
    if _stderr_only:
        stream = sys.stderr
    _finish_status()
    prefix = " " * (_indent_level * INDENT_WIDTH)
    if _timestamps:
        prefix = f"[{time.strftime('%H:%M:%S')}] {prefix}"
    for line in message.splitlines() or [""]:
        text = f"{marker} {line}" if marker else line
        print(f"{prefix}{colorize(text, *codes, stream=stream)}", file=stream, flush=True)


def set_stderr_only(enabled: bool) -> None:
    """Sends every message to stderr, for scripts whose stdout carries data."""
    global _stderr_only  # pylint: disable=global-statement
    _stderr_only = enabled


def set_timestamps(enabled: bool) -> None:
    """Puts [HH:MM:SS] in front of every printed line."""
    global _timestamps  # pylint: disable=global-statement
    _timestamps = enabled


def set_quiet(quiet: bool) -> None:
    """Silences header, info, detail and plain; success, warnings and errors are still printed."""
    global _quiet  # pylint: disable=global-statement
    _quiet = quiet


def _finish_status() -> None:
    global _status_stream  # pylint: disable=global-statement
    if _status_stream is not None:
        print(file=_status_stream, flush=True)
        _status_stream = None


def status(message: str) -> None:
    """Shows a transient status on the current line, replaced by the next call and ended by the next message."""
    global _status_stream  # pylint: disable=global-statement
    stream = sys.stderr if _stderr_only else sys.stdout
    _status_stream = stream
    print(f"\r{colorize(message, CYAN, stream=stream)}  ", end="", file=stream, flush=True)


@contextlib.contextmanager
def indent(levels: int = 1) -> Iterator[None]:
    """Indents everything printed inside the with block."""
    global _indent_level  # pylint: disable=global-statement
    _indent_level += levels
    try:
        yield
    finally:
        _indent_level -= levels


def header(message: str) -> None:
    """Prints a bold section header."""
    _emit(message, ">>>", (BOLD, MAGENTA), sys.stdout, quietable=True)


def info(message: str) -> None:
    """Prints an informational message."""
    _emit(message, ">", (BLUE,), sys.stdout, quietable=True)


def success(message: str) -> None:
    """Prints a success message."""
    _emit(message, "✓", (GREEN,), sys.stdout)


def warn(message: str) -> None:
    """Prints a warning to stderr."""
    _emit(message, "!", (YELLOW,), sys.stderr)


def error(message: str) -> None:
    """Prints an error to stderr."""
    _emit(message, "✗", (RED,), sys.stderr)


def detail(message: str) -> None:
    """Prints a dimmed line without a marker, for command output and other detail."""
    _emit(message, "", (DIM,), sys.stdout, quietable=True)


def plain(message: str) -> None:
    """Prints an unstyled line at the current indent."""
    _emit(message, "", (), sys.stdout, quietable=True)


def die(message: str, exit_code: int = 1) -> NoReturn:
    """Prints an error and exits."""
    error(message)
    sys.exit(exit_code)
