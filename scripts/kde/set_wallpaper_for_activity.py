#!/usr/bin/env python3
"""Sets the wallpaper of one KDE activity through plasmashell.

Usage:
    set_wallpaper_for_activity.py <activity-name> <path-to-image>
"""

import json
import pathlib
import shutil
import subprocess
import sys
from collections.abc import Sequence

# The helpers package sits next to the script folders, which are not on the import path.
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
from helpers import log  # pylint: disable=wrong-import-position

QDBUS_CANDIDATES = ("/usr/lib/qt6/bin/qdbus", "qdbus-qt6", "qdbus")
QT_INSTALLATION_ERROR = "qdbus: could not find a Qt installation"
PLASMASHELL_ARGS = ("org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell.evaluateScript")

EXIT_USAGE = 1
EXIT_NO_ACTIVITIES = 2
EXIT_UNKNOWN_ACTIVITY = 3
EXIT_IMAGE_MISSING = 4
EXIT_APPLY_FAILED = 5

LIST_ACTIVITIES_SCRIPT = """
var activityIds = {};
var allActivities = activities();
for (var i = 0; i < allActivities.length; i++) {
  var id = allActivities[i];
  activityIds[activityName(id)] = id;
}
print(JSON.stringify(activityIds));
""".strip()

# Writes the image to every desktop of the activity and reloads it, so the change shows without a restart.
SET_WALLPAPER_SCRIPT = """
var desktopList = desktopsForActivity("%s");
for (var i = 0; i < desktopList.length; i++) {
  var desktop = desktopList[i];
  desktop.wallpaperPlugin = "org.kde.image";
  desktop.currentConfigGroup = Array("Wallpaper","org.kde.image","General");
  desktop.writeConfig("Image", "%s");
  if (typeof desktop.reloadConfig === "function") {
    try { desktop.reloadConfig(); } catch (e) { /* ignore reload errors */ }
  }
}
""".strip()


def run_command(command: Sequence[str]) -> tuple[str, int]:
    """Runs a command and returns its combined stdout and stderr with the exit code."""
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    return (f"{result.stdout}\n{result.stderr}").strip(), result.returncode


def evaluate_plasma_script(script: str) -> str:
    """Runs a script inside plasmashell.

    Tries each qdbus binary and falls back to dbus-send.

    Args:
        script: Plasma desktop scripting JavaScript.

    Returns:
        The script output, empty when plasmashell printed nothing.
    """
    for candidate in QDBUS_CANDIDATES:
        path = shutil.which(candidate) or (candidate if pathlib.Path(candidate).exists() else None)
        if path is None:
            continue
        output, _ = run_command([path, *PLASMASHELL_ARGS, script])
        if QT_INSTALLATION_ERROR not in output:
            return output

    output, _ = run_command(
        [
            "dbus-send",
            "--session",
            "--dest=org.kde.plasmashell",
            "/PlasmaShell",
            "org.kde.PlasmaShell.evaluateScript",
            f"string:{script}",
        ]
    )
    return output


def get_activities() -> dict[str, str]:
    """Returns a mapping from activity name to activity id.

    Raises:
        RuntimeError: plasmashell did not answer or its output is not JSON.
    """
    output = evaluate_plasma_script(LIST_ACTIVITIES_SCRIPT)
    if not output:
        raise RuntimeError("Could not get activities from plasmashell. Make sure plasmashell is running.")
    try:
        return json.loads(output)
    except json.JSONDecodeError as e:
        raise RuntimeError(f"Could not parse JSON from plasmashell. Output:\n{output}") from e


def apply_wallpaper(activity_id: str, image_path: str) -> None:
    """Applies the image to every desktop of the activity.

    Raises:
        FileNotFoundError: The image does not exist.
    """
    image = pathlib.Path(image_path).expanduser().resolve()
    if not image.exists():
        raise FileNotFoundError(str(image))
    evaluate_plasma_script(SET_WALLPAPER_SCRIPT % (activity_id, image.as_uri()))


def main(argv: Sequence[str]) -> int:
    """Looks up the activity by name and sets its wallpaper."""
    if len(argv) != 3 or argv[1] in ("-h", "--help"):
        log.plain(f"Usage: {argv[0]} <activity-name> <path-to-image>")
        log.plain(f"Example: {argv[0]} 'Default' ~/Pictures/Wallpapers/Misc/1.jpg")
        return EXIT_USAGE

    activity_name, image_path = argv[1], argv[2]

    try:
        activities = get_activities()
    except RuntimeError as e:
        log.error(f"Error getting activities: {e}")
        return EXIT_NO_ACTIVITIES

    if activity_name not in activities:
        log.error(f"Activity named '{activity_name}' not found. Available activities:")
        with log.indent():
            for name in sorted(activities):
                log.plain(f"- {name}")
        return EXIT_UNKNOWN_ACTIVITY

    activity_id = activities[activity_name]
    try:
        apply_wallpaper(activity_id, image_path)
    except FileNotFoundError:
        log.error(f"Image file not found: {image_path}")
        return EXIT_IMAGE_MISSING
    except OSError as e:
        log.error(f"Error applying wallpaper: {e}")
        return EXIT_APPLY_FAILED

    log.success(f"Applied wallpaper '{image_path}' to activity '{activity_name}' ({activity_id}).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
