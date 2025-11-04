#!/usr/bin/env python3

import json
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Dict

def findQdbusCandidates() -> list:
  return ["/usr/lib/qt6/bin/qdbus", "qdbus-qt6", "qdbus"]

def runCmd(cmd: list) -> tuple:
  p = subprocess.run(cmd, capture_output=True, text=True)
  return (p.stdout or "", p.stderr or "", p.returncode)

def getActivitiesMap() -> Dict[str, str]:
  js = r'''
var m = {};
var a = activities();
for (var i = 0; i < a.length; i++) {
  var id = a[i];
  m[activityName(id)] = id;
}
print(JSON.stringify(m));
'''.strip()

  qtInstallErr = "qdbus: could not find a Qt installation"
  for candidate in findQdbusCandidates():
    path = shutil.which(candidate) or (candidate if Path(candidate).exists() else None)
    if not path:
      continue
    out, err, code = runCmd([path, "org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell.evaluateScript", js])
    combined = (out + "\n" + err).strip()
    if qtInstallErr in combined:
      continue
    if combined:
      try:
        return json.loads(combined)
      except Exception:
        raise RuntimeError("Could not parse JSON from plasmashell. Output:\n" + combined)

  out, err, code = runCmd([
    "dbus-send", "--session", "--dest=org.kde.plasmashell",
    "/PlasmaShell", "org.kde.PlasmaShell.evaluateScript", f"string:{js}"
  ])
  combined = (out + "\n" + err).strip()
  if combined:
    try:
      return json.loads(combined)
    except Exception:
      raise RuntimeError("Could not parse JSON from plasmashell (dbus-send). Output:\n" + combined)

  raise RuntimeError("Could not get activities from plasmashell. Make sure plasmashell is running in your session.")

def applyWallpaper(activityId: str, imagePath: str) -> None:
  """Apply image to every desktop returned by desktopsForActivity(activityId) and reload."""
  p = Path(imagePath).expanduser().resolve()
  if not p.exists():
    raise FileNotFoundError(str(p))
  fileUrl = "file://" + str(p)

  # Use desktopsForActivity(...) and call reloadConfig() after writeConfig.
  js_template = r'''
var ds = desktopsForActivity("%s");
for (var i = 0; i < ds.length; i++) {
  var d = ds[i];
  d.wallpaperPlugin = "org.kde.image";
  d.currentConfigGroup = Array("Wallpaper","org.kde.image","General");
  d.writeConfig("Image", "%s");
  if (typeof d.reloadConfig === "function") {
    try { d.reloadConfig(); } catch (e) { /* ignore reload errors */ }
  }
}
'''.strip() % (activityId, fileUrl)

  qtInstallErr = "qdbus: could not find a Qt installation"
  for candidate in findQdbusCandidates():
    path = shutil.which(candidate) or (candidate if Path(candidate).exists() else None)
    if not path:
      continue
    out, err, code = runCmd([path, "org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell.evaluateScript", js_template])
    combined = (out + "\n" + err).strip()
    if qtInstallErr in combined:
      continue
    # assume success if no Qt-installation error
    return

  # fallback to dbus-send
  runCmd([
    "dbus-send", "--session", "--dest=org.kde.plasmashell",
    "/PlasmaShell", "org.kde.PlasmaShell.evaluateScript", f"string:{js_template}"
  ])
  return

def printHelp(prog: str) -> None:
  print(f"Usage: {prog} <activity-name> <path-to-image>")
  print("Example: ./set-wallpaper.py 'Default' ~/Pictures/Wallpapers/Misc/1.jpg")

def main(argv) -> int:
  if len(argv) != 3 or argv[1] in ("-h", "--help"):
    printHelp(argv[0])
    return 1

  activityName = argv[1]
  imagePath = argv[2]

  try:
    activities = getActivitiesMap()
  except Exception as e:
    print("Error getting activities:", e, file=sys.stderr)
    return 2

  if activityName not in activities:
    print(f"Activity named '{activityName}' not found. Available activities:")
    for name in sorted(activities.keys()):
      print(" -", name)
    return 3

  activityId = activities[activityName]
  try:
    applyWallpaper(activityId, imagePath)
  except FileNotFoundError:
    print("Error: image file not found:", imagePath, file=sys.stderr)
    return 4
  except Exception as e:
    print("Error applying wallpaper:", e, file=sys.stderr)
    return 5

  print(f"Applied wallpaper '{imagePath}' to activity '{activityName}' ({activityId}).")
  return 0

if __name__ == "__main__":
  raise SystemExit(main(sys.argv))
