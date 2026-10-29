#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Name:        focus_or_launch.py
# Description: Focus an app's window on the current virtual desktop, or launch
#              a new window if there is none (what the Meta+T/E/D keys do).
#
# Details:
#   "Moved under the mouse" below means: only when the window is on another
#   screen than the pointer; a window on the pointer's screen is just focused.
#
#   konsole:
#     If a window on the current virtual desktop (and activity) has a tab that
#     is not running Claude Code, the topmost such window is focused and moved
#     under the mouse. Otherwise (no window, or only Claude Code ones) a new
#     window is launched.
#
#   kate:
#     Reuses an "Untitled" tab before making anything new. Windows on the
#     current desktop are searched, the topmost first, and within a window
#     every tab (Kate cannot list documents over D-Bus, so the tabs are stepped
#     through and the window title read). The window that has one is focused,
#     moved under the mouse and switched to that tab. If no window has an
#     Untitled tab, the topmost gets a new one; with no window, a new one is
#     launched.
#
#   dolphin:
#     A window on the current desktop that is not focused is brought forward
#     and moved under the mouse. If one is already focused, it gets a new tab
#     showing the home folder. No window: a new one is launched.
#
#   firefox [URL]:
#     The topmost window on the current desktop is focused (not moved) and a
#     new tab is opened in it, showing URL if given. With no window here, a new
#     window is opened on this desktop, even if Firefox runs on another one.
#     firefox.desktop sends clicked links here.
#
#   chromium [URL...]:
#     The same as firefox, through open_chromium.sh (profile by activity).
#     chromium.desktop sends clicked links and files here.
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
import subprocess
import sys
import time

import dbus


sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import kwin_windows  # noqa: E402


# ==== Configuration ====
SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
OPEN_FIREFOX = os.path.join(SCRIPT_DIR, "open_firefox.sh")
OPEN_CHROMIUM = os.path.join(SCRIPT_DIR, "open_chromium.sh")
FIREFOX_BIN = "/usr/bin/firefox"
KEEPASSXC_CMD = [
    "/usr/bin/flatpak",
    "run",
    "--branch=stable",
    "--arch=x86_64",
    "--command=keepassxc",
    "org.keepassxc.KeePassXC",
]
CLAUDE_COMMANDS = ("claude",)
# How long Kate gets to change its window title after a tab switch, and how many tabs are looked at per window.
KATE_TAB_WAIT_S = 0.5
KATE_MAX_TABS = 200
# How long to wait for the app to notice it got focused before asking it for a new tab.
FOCUS_WAIT_S = 1.0
FOCUS_POLL_S = 0.05


# ==== Helpers ====
def launch(cmd):
    subprocess.Popen(
        cmd, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True
    )


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
def kate_title(bus, service, path):
    """The title of the tab Kate shows in a main window, "Untitled [*]" for a new document."""
    return str(qt_prop(bus, service, path, "windowTitle"))


def kate_is_untitled(title):
    return title.replace("[*]", "").strip() == "Untitled"


def kate_main_window(bus, service):
    paths = [f"/kate/{n}" for n in sorted(child_nodes(bus, service, "/kate")) if n.startswith("MainWindow_")]
    return paths[0] if paths else None


def kate_trigger(bus, service, path, action):
    bus.get_object(service, f"{path}/actions/{action}").trigger(dbus_interface="org.qtproject.Qt.QAction")


def kate_focus_untitled_tab(bus, service, path):
    """Switches the window to its Untitled tab if it has one; returns whether it does.

    Kate cannot list its documents over D-Bus, so the tabs are stepped through (next tab wraps around) and the window
    title is read after each step. Without an Untitled tab the loop ends on the tab it started on.
    """
    start = title = kate_title(bus, service, path)
    if kate_is_untitled(title):
        return True
    for _ in range(KATE_MAX_TABS):
        kate_trigger(bus, service, path, "view_next_tab")
        deadline = time.monotonic() + KATE_TAB_WAIT_S
        new = title
        while new == title and time.monotonic() < deadline:
            time.sleep(FOCUS_POLL_S)
            new = kate_title(bus, service, path)
        if new == title:
            return False  # the title did not change: a single tab
        title = new
        if kate_is_untitled(title):
            return True
        if title == start:
            return False
    return False


def kate():
    """Reuses an existing Untitled tab (any window on this desktop) before making a new tab or window."""
    bus = dbus.SessionBus()
    windows = sorted(
        kwin_windows.list_windows(r"^org\.kate$|^org\.kde\.kate$", here_only=True),
        key=lambda w: w["stackIndex"],
        reverse=True,
    )
    if not windows:
        launch(["kate", "-n"])
        return

    targets = []
    for w in windows:
        service = f"org.kde.kate-{w['pid']}"
        try:
            path = kate_main_window(bus, service)
        except dbus.DBusException:
            path = None
        if path:
            targets.append((w, service, path))
    if not targets:
        kwin_windows.activate(windows[0]["id"], to_cursor=True)
        return

    # Windows already showing an Untitled tab first, then the rest, each stepped through its tabs.
    try:
        ordered = sorted(targets, key=lambda t: not kate_is_untitled(kate_title(bus, t[1], t[2])))
        for w, service, path in ordered:
            if kate_focus_untitled_tab(bus, service, path):
                kwin_windows.activate(w["id"], to_cursor=True)
                return
    except dbus.DBusException:
        pass
    # No Untitled tab anywhere: a new one in the topmost window.
    w, service, path = targets[0]
    kwin_windows.activate(w["id"], to_cursor=True)
    trigger_in_active_window(service, "/kate", "MainWindow_", "file_new")


def dolphin():
    windows = kwin_windows.list_windows(r"^org\.kde\.dolphin$", here_only=True)
    if not windows:
        launch(["dolphin", "--new-window"])
        return
    # A window that is already focused gets a new tab; otherwise the first press only brings the topmost one forward.
    window = next((w for w in windows if w["active"]), None)
    if window is None:
        kwin_windows.activate(topmost(windows)["id"], to_cursor=True)
        return
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
                dbus_interface="org.kde.konsole.Session"
            )
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


def firefox(url=None):
    def new_tab(w):
        # Firefox opens remote --new-tab requests in its most recently focused window, so let focus settle first.
        time.sleep(0.2)
        launch([FIREFOX_BIN, *firefox_profile_args(w["pid"]), "--new-tab", url or "about:newtab"])

    focus_here_or_launch(r"^firefox$", new_tab, [OPEN_FIREFOX, "--new-window", url] if url else [OPEN_FIREFOX])


def chromium(*urls):
    def new_tab(_):
        # Chromium opens remote URLs in the profile's most recently focused window, so let focus settle first.
        # shortcut: every window is one process, so the profile comes from the activity, not from the window found here.
        time.sleep(0.2)
        launch([OPEN_CHROMIUM, *(urls or ["chrome://newtab"])])

    focus_here_or_launch(r"^chromium$", new_tab, [OPEN_CHROMIUM, "--new-window", *urls])


def keepassxc():
    window = topmost(kwin_windows.list_windows(r"(?i)keepassxc"))
    if window is not None:
        kwin_windows.activate(window["id"], move_here=True)
        return
    # Not mapped (hidden to tray or not running): the single-instance launcher shows the running one.
    launch(KEEPASSXC_CMD)


APPS = {
    "kate": kate,
    "dolphin": dolphin,
    "konsole": konsole,
    "firefox": firefox,
    "chromium": chromium,
    "keepassxc": keepassxc,
}


def main():
    parser = argparse.ArgumentParser(description=__doc__ or "Focus or launch an app on the current desktop.")
    parser.add_argument("app", choices=sorted(APPS))
    parser.add_argument("urls", nargs="*", help="firefox (one) and chromium only: the links to open")
    args = parser.parse_args()
    APPS[args.app](*args.urls)


if __name__ == "__main__":
    main()
