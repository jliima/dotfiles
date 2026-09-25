#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Name:        kwin_windows.py
# Description: List and activate KWin windows from Python (Wayland-compatible).
#
# Details:
#   Loads a throwaway KWin script over D-Bus that reports back to this process
#   through callDBus(). Used by focus-or-launch.py, but also runnable directly:
#
#     kwin_windows.py list [CLASS_REGEX] [--here]
#     kwin_windows.py activate WINDOW_ID [--move-here]
# ------------------------------------------------------------------------------

import argparse
import json
import os
import re
import tempfile
import uuid

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

# Must be set before any session bus connection is made, including ones made by importers.
DBusGMainLoop(set_as_default=True)

# ==== Configuration ====
TIMEOUT_MS = 2000
RECEIVER_PATH = "/KwinWindowsReceiver"
RECEIVER_IFACE = "local.dotfiles.KwinWindows"

# Serialises every normal window plus whether it is on the current desktop and activity.
LIST_JS = """
const out = [];
const desk = workspace.currentDesktop;
const act = workspace.currentActivity;
const stack = workspace.stackingOrder;
for (const w of workspace.windowList()) {
  if (!w.normalWindow || w.skipTaskbar) continue;
  const onDesk = w.onAllDesktops || w.desktops.some(d => d.id === desk.id);
  const onAct = w.activities.length === 0 || w.activities.includes(act);
  out.push({
    id: w.internalId.toString(), pid: w.pid, caption: w.caption, resourceClass: w.resourceClass,
    desktopFile: w.desktopFileName, minimized: w.minimized, active: w === workspace.activeWindow,
    here: onDesk && onAct, stackIndex: stack.indexOf(w),
  });
}
callDBus("%(bus)s", "%(path)s", "%(iface)s", "result", JSON.stringify(out));
"""

# Optionally moves the window to the current desktop/activity, then unminimizes and focuses it.
ACTIVATE_JS = """
let ok = false;
for (const w of workspace.windowList()) {
  if (w.internalId.toString() !== "%(id)s") continue;
  if (%(move)s) {
    w.desktops = [workspace.currentDesktop];
    if (w.activities.length !== 0) w.activities = [workspace.currentActivity];
  }
  w.minimized = false;
  workspace.activeWindow = w;
  ok = true;
}
callDBus("%(bus)s", "%(path)s", "%(iface)s", "result", JSON.stringify(ok));
"""


class _Receiver(dbus.service.Object):
  def __init__(self, bus, loop):
    super().__init__(bus, RECEIVER_PATH)
    self.loop = loop
    self.payload = None

  @dbus.service.method(RECEIVER_IFACE, in_signature="s", out_signature="")
  def result(self, payload):
    self.payload = str(payload)
    self.loop.quit()


def _run_script(template, **params):
  """Runs a KWin script built from template and returns the JSON it reports back."""
  bus = dbus.SessionBus()
  loop = GLib.MainLoop()
  receiver = _Receiver(bus, loop)
  source = template % dict(params, bus=bus.get_unique_name(), path=RECEIVER_PATH, iface=RECEIVER_IFACE)

  plugin = f"dotfiles-kwin-windows-{uuid.uuid4().hex}"
  scripting = dbus.Interface(bus.get_object("org.kde.KWin", "/Scripting"), "org.kde.kwin.Scripting")
  with tempfile.NamedTemporaryFile("w", suffix=".js", delete=False) as f:
    f.write(source)
    script_file = f.name
  try:
    script_id = scripting.loadScript(script_file, plugin, signature="ss")
    script = dbus.Interface(bus.get_object("org.kde.KWin", f"/Scripting/Script{script_id}"), "org.kde.kwin.Script")
    GLib.timeout_add(TIMEOUT_MS, loop.quit)
    script.run()
    loop.run()
  finally:
    scripting.unloadScript(plugin)
    os.unlink(script_file)
    receiver.remove_from_connection()

  if receiver.payload is None:
    raise TimeoutError("KWin script did not report back")
  return json.loads(receiver.payload)


def list_windows(class_regex=None, here_only=False):
  """Returns normal windows, optionally filtered by resourceClass regex and current desktop."""
  windows = _run_script(LIST_JS)
  if class_regex:
    pattern = re.compile(class_regex)
    windows = [w for w in windows if pattern.search(w["resourceClass"]) or pattern.search(w["desktopFile"])]
  if here_only:
    windows = [w for w in windows if w["here"]]
  return windows


def activate(window_id, move_here=False):
  """Focuses the window, first moving it to the current desktop when move_here is set."""
  return _run_script(ACTIVATE_JS, id=window_id, move="true" if move_here else "false")


def main():
  parser = argparse.ArgumentParser(description="List and activate KWin windows.")
  sub = parser.add_subparsers(dest="command", required=True)
  p_list = sub.add_parser("list", help="print matching windows as JSON")
  p_list.add_argument("class_regex", nargs="?")
  p_list.add_argument("--here", action="store_true", help="only windows on the current desktop and activity")
  p_act = sub.add_parser("activate", help="focus a window by id")
  p_act.add_argument("window_id")
  p_act.add_argument("--move-here", action="store_true", help="move it to the current desktop first")
  args = parser.parse_args()

  if args.command == "list":
    print(json.dumps(list_windows(args.class_regex, args.here), indent=2, ensure_ascii=False))
  else:
    print(json.dumps(activate(args.window_id, args.move_here)))


if __name__ == "__main__":
  main()
