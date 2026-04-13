#!/usr/bin/env python3
"""Run pywal and execute application-specific theme scripts.

This script runs pywal with the specified arguments and then executes
all application scripts in the applications directory to apply the theme.
"""

import argparse
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
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

WAL_COLORSCHEMES_DIR = Path.home() / ".config/wal/colorschemes"
WALLPAPER_SETTER_SCRIPT = Path.home() / "scripts/kde/set-wallpaper-for-activity.py"

# Lock for thread-safe printing
print_lock = threading.Lock()


def print_status(message: str, color: str = Colors.RESET) -> None:
  """Print a status message with color (thread-safe)."""
  with print_lock:
    print(f"{color}{message}{Colors.RESET}")


def print_header(message: str) -> None:
  """Print a header message."""
  print_status(f"{Colors.BOLD}{message}{Colors.RESET}", Colors.CYAN)


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


def print_debug_output(output: str) -> None:
  """Print captured debug output, prefixing each line with two spaces."""
  with print_lock:
    for line in output.splitlines():
      print(f"  {line}")


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


def run_application_script(
  script: Path, debug: bool
) -> tuple[Path, bool, int | None, str | None, str, str]:
  """Run a single application script.

  Args:
    script: Path to the script to run.
    debug: Whether to show script output.

  Returns:
    Tuple of (script, success, return_code, error_message, stdout, stderr).
  """
  if not script.is_file():
    return script, False, None, "not a file"

  if not os.access(script, os.X_OK):
    return script, False, None, "not executable"

  try:
    if debug:
      result = subprocess.run([str(script)], check=False, capture_output=True, text=True)
    else:
      result = subprocess.run([str(script)], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    if result.returncode == 0:
      return script, True, result.returncode, None, result.stdout if debug else "", result.stderr if debug else ""
    else:
      return script, False, result.returncode, None, result.stdout if debug else "", result.stderr if debug else ""
  except Exception as e:
    return script, False, None, str(e), "", ""


def run_application_scripts(scripts: list[Path], apps_dir: Path, debug: bool) -> tuple[int, int]:
  """Run all application scripts in parallel.

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

  print_status(f"  Found {len(scripts)} scripts in {apps_dir}", Colors.CYAN)

  success_count = 0
  failure_count = 0

  # Run scripts in parallel using ThreadPoolExecutor
  with ThreadPoolExecutor() as executor:
    # Submit all scripts for execution
    futures = {executor.submit(run_application_script, script, debug): script for script in scripts}

    # Process results as they complete
    for future in as_completed(futures):
      script, success, return_code, error_msg, stdout, stderr = future.result()

      if debug:
        if stdout.strip():
          print_status(f"  Output from {script.name} (stdout):", Colors.MAGENTA)
          print_debug_output(stdout)
        if stderr.strip():
          print_status(f"  Output from {script.name} (stderr):", Colors.YELLOW)
          print_debug_output(stderr)

      if success:
        print_success(script.name)
        success_count += 1
      elif error_msg:
        if error_msg in ("not a file", "not executable"):
          print_skipped(script.name, error_msg)
        else:
          print_status(f"  ✗ Error running {script.name}: {error_msg}", Colors.RED)
        failure_count += 1
      else:
        print_failure(script.name, return_code)
        failure_count += 1

  return success_count, failure_count


def open_script_in_editor(script_name: str) -> int:
  """Open the specified application script in VS Code.

  Args:
    script_name: Name of the script to open (with or without .sh extension).

  Returns:
    Exit code (0 on success, 1 on failure).
  """
  apps_dir = get_applications_dir()

  # Support both with and without .sh extension
  script_file = script_name if script_name.endswith(".sh") else f"{script_name}.sh"
  script_path = apps_dir / script_file

  if not script_path.is_file():
    print_status(f"Error: Script not found: {script_path}", Colors.RED)
    return 1

  try:
    result = subprocess.run(["code", str(script_path)], check=False)
    return result.returncode
  except FileNotFoundError:
    print_status("Error: 'code' command not found. Is VS Code installed?", Colors.RED)
    return 1


def find_theme(theme_name: str) -> tuple[Path | None, bool]:
  """Find a theme file in the dark or light colorschemes directory.

  Returns:
    Tuple of (theme_path, is_light). theme_path is None if not found.
  """
  # If given an explicit path that already exists, detect folder from its location
  candidate = Path(theme_name).expanduser()
  if candidate.exists():
    resolved = candidate.resolve()
    is_light = (WAL_COLORSCHEMES_DIR.resolve() / "light") in resolved.parents
    return resolved, is_light

  theme_file = theme_name if theme_name.endswith(".json") else f"{theme_name}.json"

  dark_path = WAL_COLORSCHEMES_DIR / "dark" / theme_file
  if dark_path.exists():
    return dark_path, False

  light_path = WAL_COLORSCHEMES_DIR / "light" / theme_file
  if light_path.exists():
    return light_path, True

  return None, False


def resolve_wal_args(wal_args: list[str]) -> tuple[list[str], Path | None]:
  """Auto-detect light themes and add -l flag when needed.

  Returns:
    Tuple of (updated_wal_args, theme_file_path).
  """
  updated_args = list(wal_args)
  theme_path = None

  for i, arg in enumerate(wal_args):
    if arg in ("--theme", "-f") and i + 1 < len(wal_args):
      path, is_light = find_theme(wal_args[i + 1])
      theme_path = path
      if is_light and "-l" not in wal_args:
        updated_args.append("-l")
      break

  return updated_args, theme_path


def _get_current_activity_id() -> str | None:
  """Get the UUID of the currently active KDE Plasma activity."""
  candidates = ["/usr/lib/qt6/bin/qdbus", "qdbus-qt6", "qdbus"]
  for candidate in candidates:
    path = shutil.which(candidate) or (candidate if Path(candidate).exists() else None)
    if not path:
      continue
    result = subprocess.run(
      [path, "org.kde.ActivityManager", "/ActivityManager/Activities", "CurrentActivity"],
      capture_output=True,
      text=True,
    )
    if result.returncode == 0 and result.stdout.strip():
      return result.stdout.strip()

  # Fallback: dbus-send
  result = subprocess.run(
    [
      "dbus-send", "--session", "--dest=org.kde.ActivityManager",
      "--print-reply", "/ActivityManager/Activities",
      "org.kde.ActivityManager.Activities.CurrentActivity",
    ],
    capture_output=True,
    text=True,
  )
  for line in result.stdout.splitlines():
    if "string" in line:
      parts = line.strip().split('"')
      if len(parts) >= 2:
        return parts[1]

  return None


def set_plasma_wallpaper(theme_file: Path | None, debug: bool) -> None:
  """Set the Plasma wallpaper for the current activity if the theme defines one."""
  if not theme_file or not theme_file.exists():
    return

  try:
    theme_data = json.loads(theme_file.read_text())
  except Exception as e:
    if debug:
      print_status(f"  Could not parse theme file: {e}", Colors.YELLOW)
    return

  wallpaper = theme_data.get("wallpaper")
  if not wallpaper:
    return

  wallpaper_path = Path(wallpaper).expanduser().resolve()
  print_header("Setting Plasma wallpaper")
  print_status(f"  Wallpaper: {wallpaper_path}", Colors.MAGENTA)

  if not wallpaper_path.exists():
    print_status(f"  ✗ Wallpaper file not found: {wallpaper_path}", Colors.RED)
    return

  if not WALLPAPER_SETTER_SCRIPT.exists():
    print_status(f"  ✗ Wallpaper setter not found: {WALLPAPER_SETTER_SCRIPT}", Colors.RED)
    return

  spec = importlib.util.spec_from_file_location("set_wallpaper_for_activity", WALLPAPER_SETTER_SCRIPT)
  mod = importlib.util.module_from_spec(spec)
  try:
    spec.loader.exec_module(mod)
  except Exception as e:
    print_status(f"  ✗ Could not load wallpaper setter: {e}", Colors.RED)
    return

  activity_id = _get_current_activity_id()
  if not activity_id:
    print_status("  ✗ Could not determine current Plasma activity", Colors.RED)
    return

  try:
    mod.applyWallpaper(activity_id, str(wallpaper_path))
    print_status("  ✓ Wallpaper applied to current activity", Colors.GREEN)
  except FileNotFoundError:
    print_status(f"  ✗ Wallpaper file not found: {wallpaper_path}", Colors.RED)
  except Exception as e:
    print_status(f"  ✗ Failed to set wallpaper: {e}", Colors.RED)


def create_parser() -> argparse.ArgumentParser:
  """Create the argument parser."""
  parser = argparse.ArgumentParser(
    description="Run pywal and execute application-specific theme scripts.",
    epilog="This script also supports all wal flags. Run 'wal -h' or 'wal --help' to see available wal options.",
    formatter_class=argparse.RawDescriptionHelpFormatter,
  )

  parser.add_argument(
    "--open-script",
    metavar="SCRIPT",
    help="Open the specified application script in the default editor. "
         "Ignores all other flags when used.",
  )

  parser.add_argument(
    "--app",
    nargs="+",
    metavar="SCRIPT",
    help="Specify which application script(s) to run. Multiple scripts can be specified. "
         "If not specified, all scripts in the applications directory will be run.",
  )

  parser.add_argument(
    "--debug",
    action="store_true",
    help="Display the output of each application script.",
  )

  return parser


def parse_args(args: list[str]) -> tuple[argparse.Namespace, list[str], Path | None]:
  """Parse command line arguments.

  Separates our script's arguments from wal arguments.

  Args:
    args: Command line arguments.

  Returns:
    Tuple of (parsed_args, wal_args, theme_file_path).
  """
  parser = create_parser()

  # Separate known args (ours) from unknown args (for wal)
  known_args, wal_args = parser.parse_known_args(args)

  # If no theme-related args provided to wal, use default theme
  theme_flags = {"--theme", "-f"}
  has_theme = any(arg in theme_flags for arg in wal_args)

  if not has_theme:
    wal_args = ["--theme", DEFAULT_THEME] + wal_args

  # Resolve theme path and auto-add -l for light themes
  wal_args, theme_path = resolve_wal_args(wal_args)

  return known_args, wal_args, theme_path


def main() -> int:
  """Main entry point."""
  args, wal_args, theme_path = parse_args(sys.argv[1:])

  # Handle --open-script flag (ignores all other flags)
  if args.open_script:
    return open_script_in_editor(args.open_script)

  # Run wal first
  if not run_wal(wal_args, args.debug):
    print_status("\nAborting: pywal failed", Colors.RED)
    return 1

  # Set Plasma wallpaper if defined in theme
  set_plasma_wallpaper(theme_path, args.debug)

  # Get and run application scripts
  apps_dir = get_applications_dir()
  scripts = get_application_scripts(apps_dir, args.app)
  _, failure = run_application_scripts(scripts, apps_dir, args.debug)

  # Return non-zero if any scripts failed
  return 1 if failure > 0 else 0


if __name__ == "__main__":
  sys.exit(main())
