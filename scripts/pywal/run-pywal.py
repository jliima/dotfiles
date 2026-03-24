#!/usr/bin/env python3
"""Run pywal and execute application-specific theme scripts.

This script runs pywal with the specified arguments and then executes
all application scripts in the applications directory to apply the theme.
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

# ANSI color codes for terminal output
class Colors:
  RESET = "\033[0m"
  BOLD = "\033[1m"
  RED = "\033[91m"
  GREEN = "\033[92m"
  YELLOW = "\033[93m"
  BLUE = "\033[94m"
  MAGENTA = "\033[95m"
  CYAN = "\033[96m"


DEFAULT_THEME = "parecolors"


def print_status(message: str, color: str = Colors.RESET) -> None:
  """Print a status message with color."""
  print(f"{color}{message}{Colors.RESET}")


def print_header(message: str) -> None:
  """Print a header message."""
  print_status(f"\n{Colors.BOLD}{message}{Colors.RESET}", Colors.CYAN)


def print_running(script_name: str) -> None:
  """Print that a script is running."""
  print_status(f"  ▶ Running: {script_name}...", Colors.BLUE)


def print_success(script_name: str) -> None:
  """Print success status for a script."""
  print_status(f"  ✓ Success: {script_name}", Colors.GREEN)


def print_failure(script_name: str, return_code: int) -> None:
  """Print failure status for a script."""
  print_status(f"  ✗ Failed:  {script_name} (exit code: {return_code})", Colors.RED)


def print_skipped(script_name: str, reason: str) -> None:
  """Print skipped status for a script."""
  print_status(f"  ⊘ Skipped: {script_name} ({reason})", Colors.YELLOW)


def get_script_dir() -> Path:
  """Get the directory where this script is located."""
  return Path(__file__).parent.resolve()


def get_applications_dir() -> Path:
  """Get the applications directory path."""
  return get_script_dir() / "applications"


def get_application_scripts(apps_dir: Path, filter_apps: list[str] | None = None) -> list[Path]:
  """Get list of application scripts to run.

  Args:
    apps_dir: Path to the applications directory.
    filter_apps: Optional list of specific app names to run.

  Returns:
    List of script paths to execute.
  """
  if not apps_dir.is_dir():
    print_status(f"Error: Applications directory not found: {apps_dir}", Colors.RED)
    sys.exit(1)

  scripts = list(apps_dir.glob("*.sh"))

  if filter_apps:
    filtered = []
    for app in filter_apps:
      # Support both with and without .sh extension
      app_name = app if app.endswith(".sh") else f"{app}.sh"
      matching = [s for s in scripts if s.name == app_name or s.stem == app]
      if matching:
        filtered.extend(matching)
      else:
        print_status(f"Warning: Application script not found: {app}", Colors.YELLOW)
    scripts = filtered

  return scripts


def run_wal(wal_args: list[str], debug: bool) -> bool:
  """Run the wal command with the specified arguments.

  Args:
    wal_args: Arguments to pass to wal.
    debug: Whether to show wal output.

  Returns:
    True if wal succeeded, False otherwise.
  """
  print_header("Running pywal")

  cmd = ["wal"] + wal_args
  print_status(f"  Command: {' '.join(cmd)}", Colors.MAGENTA)

  try:
    if debug:
      print()
      result = subprocess.run(cmd, check=False)
    else:
      result = subprocess.run(cmd, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    if result.returncode == 0:
      print_status("  ✓ pywal completed successfully", Colors.GREEN)
      return True
    else:
      print_status(f"  ✗ pywal failed with exit code: {result.returncode}", Colors.RED)
      return False
  except FileNotFoundError:
    print_status("  ✗ Error: 'wal' command not found. Is pywal installed?", Colors.RED)
    return False


def run_application_script(script: Path, debug: bool) -> bool:
  """Run a single application script.

  Args:
    script: Path to the script to run.
    debug: Whether to show script output.

  Returns:
    True if script succeeded, False otherwise.
  """
  if not script.is_file():
    print_skipped(script.name, "not a file")
    return False

  if not os.access(script, os.X_OK):
    print_skipped(script.name, "not executable")
    return False

  print_running(script.name)

  try:
    if debug:
      # Show output in debug mode
      print_status(f"  {'─' * 50}", Colors.BLUE)
      result = subprocess.run([str(script)], check=False)
      print_status(f"  {'─' * 50}", Colors.BLUE)
    else:
      # Suppress output in normal mode
      result = subprocess.run([str(script)], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    if result.returncode == 0:
      print_success(script.name)
      return True
    else:
      print_failure(script.name, result.returncode)
      return False
  except Exception as e:
    print_status(f"  ✗ Error running {script.name}: {e}", Colors.RED)
    return False


def run_application_scripts(scripts: list[Path], apps_dir: Path, debug: bool) -> tuple[int, int]:
  """Run all application scripts.

  Args:
    scripts: List of script paths to run.
    apps_dir: Path to the applications directory.
    debug: Whether to show script output.

  Returns:
    Tuple of (success_count, failure_count).
  """
  print_header("Running application scripts")

  if not scripts:
    print_status("  No application scripts to run.", Colors.YELLOW)
    return 0, 0

  print_status(f"  Found {len(scripts)} scripts in {apps_dir}\n", Colors.CYAN)

  success_count = 0
  failure_count = 0

  for script in scripts:
    if run_application_script(script, debug):
      success_count += 1
    else:
      failure_count += 1

  return success_count, failure_count


def create_parser() -> argparse.ArgumentParser:
  """Create the argument parser."""
  parser = argparse.ArgumentParser(
    description="Run pywal and execute application-specific theme scripts.",
    epilog="This script also supports all wal flags. Run 'wal -h' or 'wal --help' to see available wal options.",
    formatter_class=argparse.RawDescriptionHelpFormatter,
  )

  parser.add_argument(
    "--app",
    action="append",
    metavar="SCRIPT",
    help="Specify which application script(s) to run. Can be used multiple times. "
         "If not specified, all scripts in the applications directory will be run.",
  )

  parser.add_argument(
    "--debug",
    action="store_true",
    help="Display the output of each application script.",
  )

  return parser


def parse_args(args: list[str]) -> tuple[argparse.Namespace, list[str]]:
  """Parse command line arguments.

  Separates our script's arguments from wal arguments.

  Args:
    args: Command line arguments.

  Returns:
    Tuple of (parsed_args, wal_args).
  """
  parser = create_parser()

  # Separate known args (ours) from unknown args (for wal)
  known_args, wal_args = parser.parse_known_args(args)

  # If no theme-related args provided to wal, use default theme
  theme_flags = {"--theme", "-f"}
  has_theme = any(arg in theme_flags for arg in wal_args)

  if not has_theme:
    wal_args = ["--theme", DEFAULT_THEME] + wal_args

  return known_args, wal_args


def main() -> int:
  """Main entry point."""
  args, wal_args = parse_args(sys.argv[1:])

  # Run wal first
  if not run_wal(wal_args, args.debug):
    print_status("\nAborting: pywal failed", Colors.RED)
    return 1

  # Get and run application scripts
  apps_dir = get_applications_dir()
  scripts = get_application_scripts(apps_dir, args.app)
  _, failure = run_application_scripts(scripts, apps_dir, args.debug)

  # Return non-zero if any scripts failed
  return 1 if failure > 0 else 0


if __name__ == "__main__":
  sys.exit(main())
