#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Name:        focus-or-launch.py
# Description: Focus an app's window on the current virtual desktop, or launch
#              a new window if there is none (what the Meta+T/E/D keys do).
#
# Details:
#   konsole:
#     If a window on the current virtual desktop (and activity) has a tab that
#     is not running Claude Code, the topmost such window is focused and moved
#     under the mouse. Otherwise (no window, or only Claude Code ones) a new
#     window is launched.
#
#   kate:
#     The topmost window on the current desktop that has a file open is
#     focused, moved under the mouse and gets a new document tab. If the only
#     windows are "Untitled" ones, the topmost is focused and moved, with no new
#     tab. No window: a new one is launched. Kate has no D-Bus call that lists
#     documents, so a window counts as "Untitled" when the title of its current
#     tab is Untitled; a file in another tab is not seen.
#
#   dolphin:
#     The topmost window on the current desktop is focused, moved under the
#     mouse and gets a new tab showing the home folder. No window: a new one.
#
#   firefox:
#     The topmost window on the current desktop is focused and a new tab is
#     opened in it, else a new window is launched.
#
#   keepassxc:
#     The KeePassXC window is moved from whatever desktop it is on to the
#     current one and focused. If it is hidden to the tray, it is shown.
#
#   Window lookup, activation and moving go through kwin_windows.py (KWin
#   scripting over D-Bus). New tabs are opened through each app's own D-Bus
#   interface. The Shift variants of the keys launch the apps themselves and do
#   not come through here.
# ------------------------------------------------------------------------------

import argparse
import os
import re
import subprocess
import sys
import time

import dbus

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import kwin_windows  # noqa: E402

# ==== Configuration ====
SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
OPEN_FIREFOX = os.path.join(SCRIPT_DIR, "open-firefox.sh")
FIREFOX_BIN = "/usr/bin/firefox"
KEEPASSXC_CMD = ["/usr/bin/flatpak", "run", "--branch=stable", "--arch=x86_64", "--command=keepassxc",
                 "org.keepassxc.KeePassXC"]
CLAUDE_COMMANDS = ("claude",)
# The title of a Kate window whose current tab is an unsaved new document, "Untitled" or "Untitled *".
KATE_UNTITLED = re.compile(r"^Untitled(?: \*)?(?: \u2014 Kate)?$")
# How long to wait for the app to notice it got focused before asking it for a new tab.
FOCUS_WAIT_S = 1.0
FOCUS_POLL_S = 0.05


# ==== Helpers ====
def launch(cmd):
  subprocess.Popen(cmd, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                   start_new_session=True)


def topmost(windows):
  return max(windows, key=lambda w: w["stackIndex"]) if windows else None


def qt_prop(bus, service, path, name):
  obj = bus.get_object(service, path)
  return obj.Get("org.qtproject.Qt.QWidget", name, dbus_interface="org.freedesktop.DBus.Properties")


def child_nodes(bus, service, path):
  xml = bus.get_object(service, path).Introspect(dbus_interface="org.freedesktop.DBus.Introspectable")
  return [part.split('"')[0] for part in xml.split('<node name="')[1:]]


def trigger_in_active_window(service, root, prefix, action):
  """Triggers a KXMLGUI action in the process's main window (/root/prefixN) that currently has focus.

  KWin activation is asynchronous, so poll until the app reports one of its windows as active.
  If none turns active in time, fall back to the first window.
  """
  bus = dbus.SessionBus()
  paths = [f"{root}/{n}" for n in sorted(child_nodes(bus, service, root)) if n.startswith(prefix)]
  if not paths:
    return

  target = None
  deadline = time.monotonic() + FOCUS_WAIT_S
  while target is None and time.monotonic() < deadline:
    target = next((p for p in paths if qt_prop(bus, service, p, "isActiveWindow")), None)
    if target is None:
      time.sleep(FOCUS_POLL_S)
  target = target or paths[0]

  bus.get_object(service, f"{target}/actions/{action}").trigger(dbus_interface="org.qtproject.Qt.QAction")


def focus_here_or_launch(class_regex, new_tab, launch_cmd, pick=topmost):
  """Shared flow: focus a window on this desktop and open a tab in it, else launch a new window."""
  window = pick(kwin_windows.list_windows(class_regex, here_only=True))
  if window is None:
    launch(launch_cmd)
    return
  kwin_windows.activate(window["id"])
  new_tab(window)


# ==== Apps ====
def kate():
  windows = kwin_windows.list_windows(r"^org\.kate$|^org\.kde\.kate$", here_only=True)
  with_file = [w for w in windows if not KATE_UNTITLED.match(w["caption"])]
  window = topmost(with_file) or topmost(windows)
  if window is None:
    launch(["kate", "-n"])
    return
  kwin_windows.activate(window["id"], to_cursor=True)
  if window in with_file:
    trigger_in_active_window(f"org.kde.kate-{window['pid']}", "/kate", "MainWindow_", "file_new")


def dolphin():
  window = topmost(kwin_windows.list_windows(r"^org\.kde\.dolphin$", here_only=True))
  if window is None:
    launch(["dolphin", "--new-window"])
    return
  kwin_windows.activate(window["id"], to_cursor=True)
  service = f"org.kde.dolphin-{window['pid']}"
  # A new tab opens at the current folder; go_home then shows the home folder in it.
  trigger_in_active_window(service, "/dolphin", "Dolphin_", "new_tab")
  trigger_in_active_window(service, "/dolphin", "Dolphin_", "go_home")


def konsole_window_path(bus, service, caption):
  """Maps a KWin window caption to the Konsole /Windows/N object whose current tab has that title."""
  for n in child_nodes(bus, service, "/Windows"):
    window = bus.get_object(service, f"/Windows/{n}")
    session = window.currentSession(dbus_interface="org.kde.konsole.Window")
    title = bus.get_object(service, f"/Sessions/{session}").title(1, dbus_interface="org.kde.konsole.Session")
    if caption == title or caption.startswith(f"{title} \u2014 "):
      return f"/Windows/{n}", session
  return None, None


def is_claude(pid):
  try:
    with open(f"/proc/{pid}/cmdline", "rb") as f:
      argv = [a.decode(errors="replace") for a in f.read().split(b"\0") if a]
    with open(f"/proc/{pid}/comm") as f:
      comm = f.read().strip()
  except OSError:
    return False
  names = [comm] + [os.path.basename(a) for a in argv[:2]]
  return any(n in CLAUDE_COMMANDS for n in names)


def konsole():
  bus = dbus.SessionBus()
  windows = kwin_windows.list_windows(r"^org\.konsole$|^org\.kde\.konsole$", here_only=True)
  # Topmost Konsole window on this desktop whose visible tab is not running Claude Code.
  for w in sorted(windows, key=lambda w: w["stackIndex"], reverse=True):
    service = f"org.kde.konsole-{w['pid']}"
    try:
      path, session = konsole_window_path(bus, service, w["caption"])
      if path is None:
        continue
      fg = bus.get_object(service, f"/Sessions/{session}").foregroundProcessId(
        dbus_interface="org.kde.konsole.Session")
    except dbus.DBusException:
      continue
    if not is_claude(fg):
      kwin_windows.activate(w["id"], to_cursor=True)
      return
  launch(["konsole"])


def firefox_profile_args(pid):
  """Returns the profile arguments the running Firefox was started with, so remoting hits that instance."""
  try:
    with open(f"/proc/{pid}/cmdline", "rb") as f:
      argv = [a.decode(errors="replace") for a in f.read().split(b"\0") if a]
  except OSError:
    return []
  for i, arg in enumerate(argv[:-1]):
    if arg in ("-P", "--P", "-profile", "--profile"):
      return [arg, argv[i + 1]]
  return []


def firefox():
  def new_tab(w):
    # Firefox opens remote --new-tab requests in its most recently focused window, so let focus settle first.
    time.sleep(0.2)
    launch([FIREFOX_BIN, *firefox_profile_args(w["pid"]), "--new-tab", "about:newtab"])

  focus_here_or_launch(r"^firefox$", new_tab, [OPEN_FIREFOX])


def keepassxc():
  window = topmost(kwin_windows.list_windows(r"(?i)keepassxc"))
  if window is not None:
    kwin_windows.activate(window["id"], move_here=True)
    return
  # Not mapped (hidden to tray or not running): the single-instance launcher shows the running one.
  launch(KEEPASSXC_CMD)


APPS = {"kate": kate, "dolphin": dolphin, "konsole": konsole, "firefox": firefox, "keepassxc": keepassxc}


def main():
  parser = argparse.ArgumentParser(description=__doc__ or "Focus or launch an app on the current desktop.")
  parser.add_argument("app", choices=sorted(APPS))
  APPS[parser.parse_args().app]()


if __name__ == "__main__":
  main()
