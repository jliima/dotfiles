#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Name:        focus-or-launch.py
# Description: Focus an app's window on the current virtual desktop and open a
#              new tab in it, or launch a new window if there is none.
#
# Details:
#   kate, dolphin, konsole, firefox:
#     If a window of the app is on the current virtual desktop (and activity),
#     the topmost one is focused and a new tab / document is opened in it.
#     Otherwise a brand new window is launched. For konsole, windows whose
#     current tab is running Claude Code are skipped, so a Claude session
#     never gets a new tab and a new window opens instead.
#
#   keepassxc:
#     The KeePassXC window is moved from whatever desktop it is on to the
#     current one and focused. If it is hidden to the tray, it is shown.
#
#   Window lookup and activation go through kwin_windows.py (KWin scripting
#   over D-Bus). New tabs are opened through each app's own D-Bus interface.
# ------------------------------------------------------------------------------

import argparse
import os
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
  def new_tab(w):
    trigger_in_active_window(f"org.kde.kate-{w['pid']}", "/kate", "MainWindow_", "file_new")

  focus_here_or_launch(r"^org\.kde\.kate$", new_tab, ["kate", "-n"])


def dolphin():
  def new_tab(w):
    trigger_in_active_window(f"org.kde.dolphin-{w['pid']}", "/dolphin", "Dolphin_", "new_tab")

  focus_here_or_launch(r"^org\.kde\.dolphin$", new_tab, ["dolphin", "--new-window"])


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
  targets = {}

  def pick(windows):
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
        targets[w["id"]] = (service, path)
        return w
    return None

  def new_tab(w):
    service, path = targets[w["id"]]
    bus.get_object(service, path).newSession(dbus_interface="org.kde.konsole.Window", signature="")

  focus_here_or_launch(r"^org\.konsole$|^org\.kde\.konsole$", new_tab, ["konsole"], pick=pick)


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
