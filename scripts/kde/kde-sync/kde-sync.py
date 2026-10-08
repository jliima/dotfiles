#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Name:        kde-sync.py
# Description: Keep KDE settings in sync between machines through the dotfiles,
#              key by key, without putting the apps' own files in git.
#
# Details:
#   Apps own their files in ~/.config: Kate rewrites katerc, kglobalaccel
#   reorders kglobalshortcutsrc and adds machine-only entries, Plasma keeps the
#   panels in an appletsrc full of desktop icon positions. So those files stay
#   out of the dotfiles. ~/.config/kde-sync (stowed) holds what is synced:
#
#     config.toml               which files, and keys that never sync
#     shared/<file>             synced keys, sorted, for every machine
#     hosts/<hostname>/<file>   keys that differ on that machine
#     plasma/panels.json        the panels and their widgets
#
#   `kde-sync sync` compares every key three ways: the live file, the dotfiles
#   (host fragment over shared), and the value both had at the last sync (kept
#   in ~/.local/state/kde-sync). A change in the app is written to the dotfiles
#   (to the host fragment if the key is there, else to shared); a change in the
#   dotfiles, e.g. from a git pull, is written to the app. If both changed, the
#   dotfiles win and the local value is printed. Shortcuts are set through
#   kglobalaccel so they work at once; panels are rebuilt through plasmashell.
#
#   kde-sync.path runs it when one of the files changes, the git hooks in
#   .githooks after a pull or rebase.
#
#   kde-sync sync [NAME...] [-n]    sync (-n: only show what would change)
#   kde-sync status                 same as sync -n
#   kde-sync local FILE GROUP KEY   keep a key per machine (to hosts/<host>/)
#   kde-sync share FILE GROUP KEY   sync a key again (back to shared/)
#   kde-sync panels save|apply      write or load plasma/panels.json by hand
#
#   GROUP is the group header without its outer brackets, e.g. "General" or
#   "Printing][Layout" for [Printing][Layout].
#
# Dependencies: python3-dbus and python3-pyqt6 (shortcuts), qdbus6 (panels).
# ------------------------------------------------------------------------------

import argparse
import fcntl
import fnmatch
import json
import os
import re
import socket
import subprocess
import sys
import tomllib
from pathlib import Path

# ==== Configuration ====
HOME = Path.home()
CONFIG = HOME / ".config/kde-sync/config.toml"
LIVE_DIR = HOME / ".config"
STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "kde-sync"
HOST = socket.gethostname()
PANELS = "panels"
PANELS_FILE = "plasma/panels.json"
# Applet and panel config that only records window sizes; left out of panels.json.
PANEL_NOISE_GROUPS = ("/ConfigDialog",)
PANEL_NOISE_KEYS = ("popupHeight", "popupWidth")
# Panel settings Themer renders per machine (the clock size, from the screen profile); run after rebuilding panels.
THEMER_PANELS_JS = Path(os.environ.get("XDG_CACHE_HOME", HOME / ".cache")) / "themer/plasma/panels.js"
# Seconds after plasmashell starts before its panels are read: it is still loading them before that.
PLASMASHELL_SETTLE_S = 30
# How a panel is shown, which the dump leaves out: properties of the scripting API's Panel object.
PANEL_VIEW_KEYS = ("screen", "thickness", "floating", "lengthMode", "opacity")
# panelOpacity in plasmashellrc; the scripting API can read a panel's opacity but not set it.
PANEL_OPACITY = {"adaptive": 0, "opaque": 1, "translucent": 2}
# The systray's own settings, which plasmashell's layout dump leaves out.
SYSTRAY_KEYS = ("extraItems", "hiddenItems", "shownItems")
APP_DIRS = [HOME / ".local/share/applications"] + [
  Path(d) / "applications" for d in os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":") if d]
APP_DIRS += [HOME / ".local/share/flatpak/exports/share/applications", Path("/var/lib/flatpak/exports/share/applications")]


# ==== Colors ====
class Colors:
  """ANSI color codes for terminal output."""

  RESET = "\033[0m"
  BOLD = "\033[1m"
  RED = "\033[91m"
  GREEN = "\033[92m"
  YELLOW = "\033[93m"
  BLUE = "\033[94m"
  MAGENTA = "\033[95m"
  CYAN = "\033[96m"


# ==== Output helpers ====
QUIET = False


def print_header(message):
  if not QUIET:
    print(f"{Colors.BOLD}{Colors.MAGENTA}>>> {message}{Colors.RESET}")


def print_success(message):
  print(f"{Colors.GREEN}✓ {message}{Colors.RESET}")


def print_error(message):
  print(f"{Colors.RED}✗ {message}{Colors.RESET}", file=sys.stderr)


def print_info(message):
  if not QUIET:
    print(f"{Colors.BLUE}> {message}{Colors.RESET}")


def print_warn(message):
  print(f"{Colors.YELLOW}! {message}{Colors.RESET}", file=sys.stderr)


def die(message):
  print_error(message)
  sys.exit(1)


# ==== Dotfiles side ====
def repo_dir():
  """The kde-sync folder in the dotfiles: where ~/.config/kde-sync/config.toml links to, wherever it was cloned."""
  if not CONFIG.exists():
    die(f"{CONFIG} not found; stow the dotfiles first")
  return CONFIG.resolve().parent


def load_config():
  with open(CONFIG, "rb") as f:
    return tomllib.load(f)


def fragment_path(name, host=None):
  return repo_dir() / ("hosts/" + host if host else "shared") / name


# ==== KConfig files ====
def split_header(line):
  """The group of a header line ("[A][B]" -> "A][B"), or None if the line is not one."""
  s = line.strip()
  return s[1:-1] if s.startswith("[") and s.endswith("]") else None


def parse_kconfig(text):
  """{(group, key): raw value} of a KConfig file, values as written (escapes kept). Keys before any group are in
  group ""."""
  values, group = {}, ""
  for line in text.splitlines():
    s = line.strip()
    if not s or s.startswith("#"):
      continue
    header = split_header(s)
    if header is not None:
      group = header
    elif "=" in s:
      key, value = s.split("=", 1)
      values[(group, key.rstrip())] = value.strip()
  return values


def format_fragment(values):
  """A fragment file: groups and keys sorted, so the same keys always give the same text."""
  out, last = [], None
  for (group, key) in sorted(values):
    if group != last:
      if out:
        out.append("")
      out.append(f"[{group}]")
      last = group
    out.append(f"{key}={values[(group, key)]}")
  return "\n".join(out) + "\n" if out else ""


def read_fragment(path):
  return parse_kconfig(path.read_text()) if path.exists() else {}


def write_fragment(path, values):
  text = format_fragment(values)
  if not text:
    if path.exists():
      path.unlink()
    return
  if not path.exists() or path.read_text() != text:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def atomic_write(path, text):
  tmp = path.with_name(f".{path.name}.kde-sync")
  tmp.write_text(text)
  if path.exists():
    os.chmod(tmp, path.stat().st_mode & 0o777)
  os.replace(tmp, path)


class KConfigFile:
  """A KConfig file edited in place: a changed key is rewritten on its own line, a new one is added at the end of its
  group, so everything else in the file stays as the app wrote it."""

  def __init__(self, path):
    self.path = path
    self.lines = path.read_text().splitlines() if path.exists() else []

  def _group_range(self, group):
    start = next((i for i, ln in enumerate(self.lines) if split_header(ln) == group), None)
    if start is None and group == "":
      start = -1
    if start is None:
      return None
    end = next((i for i in range(start + 1, len(self.lines)) if split_header(self.lines[i]) is not None),
               len(self.lines))
    return start, end

  def _key_line(self, group, key):
    rng = self._group_range(group)
    if rng is None:
      return rng, None
    for i in range(rng[0] + 1, rng[1]):
      s = self.lines[i].strip()
      if "=" in s and not s.startswith("#") and s.split("=", 1)[0].rstrip() == key:
        return rng, i
    return rng, None

  def set(self, group, key, value):
    rng, i = self._key_line(group, key)
    if i is not None:
      self.lines[i] = f"{key}={value}"
    elif rng is not None:
      at = rng[1]
      while at - 1 > rng[0] and not self.lines[at - 1].strip():
        at -= 1
      self.lines.insert(at, f"{key}={value}")
    else:
      if self.lines and self.lines[-1].strip():
        self.lines.append("")
      self.lines += [f"[{group}]", f"{key}={value}"]

  def delete(self, group, key):
    _, i = self._key_line(group, key)
    if i is not None:
      del self.lines[i]

  def save(self):
    atomic_write(self.path, "\n".join(self.lines) + "\n")


# ==== Handlers: how a kind of file is read and written ====
class IniHandler:
  """A plain KConfig file (katerc): every key syncs, a missing key is a deleted one."""

  def __init__(self, name):
    self.path = LIVE_DIR / name

  def live(self):
    return parse_kconfig(self.path.read_text()) if self.path.exists() else {}

  def present(self, k):
    return True

  def can_create(self, k):
    return True

  def apply(self, changes):
    f = KConfigFile(self.path)
    for (group, key), value in changes.items():
      if value is None:
        f.delete(group, key)
      else:
        f.set(group, key, value)
    f.save()
    return set(changes)


def split_unescaped(value, sep):
  """Splits a KConfig value at `sep` where it is not escaped with a backslash."""
  parts, cur, i = [], "", 0
  while i < len(value):
    c = value[i]
    if c == "\\" and i + 1 < len(value):
      cur += value[i:i + 2]
      i += 2
      continue
    if c == sep:
      parts.append(cur)
      cur = ""
    else:
      cur += c
    i += 1
  return parts + [cur]


def unescape(value):
  out, i = "", 0
  table = {"t": "\t", "n": "\n", "s": " ", "\\": "\\", ",": ",", ";": ";"}
  while i < len(value):
    if value[i] == "\\" and i + 1 < len(value) and value[i + 1] in table:
      out += table[value[i + 1]]
      i += 2
    else:
      out += value[i]
      i += 1
  return out


class ShortcutsHandler:
  """kglobalshortcutsrc: an entry is `action=active,default,friendly name`, or just `_launch=keys` for the launch
  shortcut of a .desktop file (group [services][name.desktop]). Only the active keys sync, and only when they differ
  from the default; set back to the default, a shortcut is dropped from the dotfiles and reset on the other machines.
  Changes are applied through kglobalaccel's D-Bus interface, which also writes the file."""

  SERVICES = "services]["

  def __init__(self, name):
    self.path = LIVE_DIR / name
    self.friendly = {}
    self.entries = set()
    self._bus = None

  def live(self):
    values = {}
    raw = parse_kconfig(self.path.read_text()) if self.path.exists() else {}
    for (group, key), value in raw.items():
      if key == "_k_friendly_name":
        self.friendly[group] = unescape(value)
        continue
      if key.startswith("_k_"):
        continue
      self.entries.add((group, key))
      fields = split_unescaped(value, ",")
      active = fields[0] or "none"
      if group.startswith(self.SERVICES):
        default = self._desktop_default(self._component(group), key)
        values[(group, key)] = None if active in ("none", default) else active
        continue
      default = (fields[1] if len(fields) > 1 else "") or "none"
      self.friendly[(group, key)] = unescape(fields[2]) if len(fields) > 2 else ""
      values[(group, key)] = None if active == default else active
    return values

  def present(self, k):
    return k in self.entries

  def can_create(self, k):
    """Only launch shortcuts of .desktop files can be added; other actions exist once their app registers them."""
    return k[0].startswith(self.SERVICES) and self._desktop_file_exists(self._component(k[0]))

  def _accel(self):
    if self._bus is None:
      import dbus
      self._bus = dbus
      bus = dbus.SessionBus()
      self._ka = dbus.Interface(bus.get_object("org.kde.kglobalaccel", "/kglobalaccel"), "org.kde.KGlobalAccel")
    return self._ka

  def _keys(self, value):
    """[[4 ints], ...] for a shortcut value as written in kglobalshortcutsrc ("Meta+Q\\tAlt+F4")."""
    from PyQt6.QtGui import QKeySequence
    out = []
    for text in unescape(value).split("\t"):
      text = text.strip()
      if not text or text == "none":
        continue
      seq = QKeySequence.fromString(text, QKeySequence.SequenceFormat.PortableText)
      ints = [seq[i].toCombined() for i in range(seq.count())]
      if ints:
        out.append((ints + [0, 0, 0, 0])[:4])
    return out

  def _component(self, group):
    return group[len(self.SERVICES):] if group.startswith(self.SERVICES) else group

  def _desktop_file_exists(self, name):
    return any((d / name).exists() for d in APP_DIRS)

  def _desktop_default(self, name, key):
    """The shortcut a .desktop file asks for (X-KDE-Shortcuts of the entry, or of the action `key`), written the way
    kglobalshortcutsrc writes it."""
    path = next((d / name for d in APP_DIRS if (d / name).exists()), None)
    if path is None:
      return None
    group = "Desktop Entry" if key == "_launch" else f"Desktop Action {key}"
    value = parse_kconfig(path.read_text(errors="replace")).get((group, "X-KDE-Shortcuts"))
    return "\\t".join(split_unescaped(value, ",")) if value else None

  def apply(self, changes):
    try:
      ka = self._accel()
    except Exception as e:
      print_warn(f"shortcuts not applied, kglobalaccel is not reachable ({e.__class__.__name__}); they are next time")
      return set()
    dbus = self._bus

    def as_dbus(keys):
      return dbus.Array([dbus.Struct((dbus.Array(k, signature="i"),)) for k in keys], signature="(ai)")

    def current(aid):
      return [[int(x) for x in s[0]] for s in ka.shortcutKeys(aid) if any(int(x) for x in s[0])]

    done, todo = set(), dict(changes)
    for _ in range(2):
      # A second round for shortcuts whose keys the first round freed elsewhere.
      for (group, key), value in list(todo.items()):
        comp = self._component(group)
        aid = [comp, key, self.friendly.get(group, ""), self.friendly.get((group, key), "")]
        if (group, key) not in self.entries:
          if not (group.startswith(self.SERVICES) and self._desktop_file_exists(comp)):
            continue
          ka.doRegister(aid)
        if value is None:
          wanted = [[int(x) for x in s[0]] for s in ka.defaultShortcutKeys(aid) if any(int(x) for x in s[0])]
        else:
          wanted = self._keys(value)
        ka.setForeignShortcutKeys(aid, as_dbus(wanted))
        if current(aid) == wanted:
          done.add((group, key))
          del todo[(group, key)]
    for group, key in todo:
      if (group, key) in self.entries or group.startswith(self.SERVICES):
        print_warn(f"shortcut [{group}] {key} not set (its keys are taken, or the action is gone)")
    return done


HANDLERS = {"ini": IniHandler, "shortcuts": ShortcutsHandler}


# ==== State ====
def load_state(name):
  f = STATE_DIR / f"{name}.json"
  if not f.exists():
    return {}
  return {tuple(k.split("\x1f", 1)): v for k, v in json.loads(f.read_text()).items()}


def save_state(name, values):
  STATE_DIR.mkdir(parents=True, exist_ok=True)
  data = {f"{g}\x1f{k}": v for (g, k), v in sorted(values.items())}
  atomic_write(STATE_DIR / f"{name}.json", json.dumps(data, indent=0, ensure_ascii=False) + "\n")


def show(v):
  return "(unset)" if v is None else v


# ==== Sync of one file ====
def sync_file(name, cfg, dry_run):
  handler = HANDLERS[cfg.get("kind", "ini")](name)
  ignore = [tuple(p) for p in cfg.get("ignore", [])]

  def ignored(k):
    return any(fnmatch.fnmatchcase(k[0], g) and fnmatch.fnmatchcase(k[1], key) for g, key in ignore)

  shared_path, host_path = fragment_path(name), fragment_path(name, HOST)
  shared, host = read_fragment(shared_path), read_fragment(host_path)
  desired = {**shared, **host}
  base = load_state(name)
  live = handler.live()

  record, apply, new_base = {}, {}, dict(base)
  for k in sorted((set(live) | set(desired) | set(base))):
    if ignored(k):
      new_base.pop(k, None)
      continue
    L, D = live.get(k), desired.get(k)
    if not handler.present(k) and L is None:
      # Not on this machine (an app that is not installed): nothing to record; set it if the app could take it.
      if D is not None and handler.can_create(k):
        apply[k] = D
      continue
    if L == D:
      new_base[k] = L
    elif k in base and base[k] == D:
      record[k] = L
    elif k not in base and D is None:
      record[k] = L
    elif (k in base and base[k] == L) or (k not in base and L is None):
      apply[k] = D
    else:
      apply[k] = D
      print_warn(f"{name} [{k[0]}] {k[1]}: {show(L)} here, {show(D)} in the dotfiles; the dotfiles win")

  for (group, key), value in record.items():
    where = "hosts/" + HOST if (group, key) in host else "shared"
    print_info(f"{name} [{group}] {key} = {show(value)}  -> dotfiles ({where})")
  for (group, key), value in apply.items():
    print_info(f"{name} [{group}] {key} = {show(value)}  -> {handler.path}")
  if dry_run:
    return bool(record or apply)

  for k, value in record.items():
    target = host if k in host else shared
    if value is None:
      target.pop(k, None)
    else:
      target[k] = value
    new_base[k] = value
  if record:
    write_fragment(shared_path, shared)
    write_fragment(host_path, host)
  if apply:
    for k in handler.apply(apply):
      new_base[k] = apply[k]
  save_state(name, {k: v for k, v in new_base.items() if v is not None})
  return bool(record or apply)


def move_key(name, group, key, to_host):
  """Moves a key between shared/ and hosts/<host>/ (local and share commands)."""
  cfg = load_config().get("files", {}).get(name)
  if cfg is None:
    die(f"{name} is not in {CONFIG}")
  shared_path, host_path = fragment_path(name), fragment_path(name, HOST)
  shared, host = read_fragment(shared_path), read_fragment(host_path)
  k = (group, key)
  src, dst = (shared, host) if to_host else (host, shared)
  value = src.pop(k, None)
  if value is None:
    live = HANDLERS[cfg.get("kind", "ini")](name).live().get(k)
    if live is None:
      die(f"[{group}] {key} is in neither {name} fragment nor the live file")
    value = live
  dst[k] = value
  write_fragment(shared_path, shared)
  write_fragment(host_path, host)
  print_success(f"[{group}] {key} is now {'kept on ' + HOST if to_host else 'shared'}: {value}")
  if not to_host:
    print_info("the other machines get this value on their next sync")


# ==== Plasma panels ====
def plasma_script(script):
  res = subprocess.run(["qdbus6", "org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell.evaluateScript", script],
                       capture_output=True, text=True)
  if res.returncode != 0:
    raise RuntimeError(res.stderr.strip() or "plasmashell is not reachable")
  return res.stdout


def panel_ignore():
  return [tuple(x) for x in load_config().get("panels", {}).get("ignore", [])]


def dump_panels():
  """The panels as plasmashell serializes them (dumpCurrentLayoutJS), without desktops and window sizes, plus the
  systray's shown and hidden items, which the dump leaves out."""
  res = subprocess.run(["qdbus6", "org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell.dumpCurrentLayoutJS"],
                       capture_output=True, text=True)
  if res.returncode != 0:
    raise RuntimeError(res.stderr.strip() or "plasmashell is not reachable")
  text = res.stdout
  layout = json.loads(text[text.index("{"):text.rindex("}") + 1])
  panels = layout.get("panels", [])
  # The dump leaves out how a panel is shown (floating, fit or fill, opacity) and gives the height of a floating panel
  # with its margins; those come from the panels themselves, matched by where they sit.
  views = json.loads(plasma_script("""
    print(JSON.stringify(panels().map(function (p) {
      return { location: p.location, alignment: p.alignment, thickness: p.height, screen: p.screen,
               floating: p.floating, lengthMode: p.lengthMode, opacity: p.opacity };
    })));
  """) or "[]")
  for panel in panels:
    view = next((v for v in views if (v["location"], v["alignment"]) == (panel.get("location"), panel.get("alignment"))),
                None)
    if view:
      views.remove(view)
      # In pixels: the dump's grid units grow with the font, which differs between screen profiles.
      panel.pop("height", None)
      panel["view"] = {k: view[k] for k in PANEL_VIEW_KEYS}
      panel.get("config", {}).get("/", {}).pop("lastScreen", None)
      if view["lengthMode"] != "custom":
        # Fit and fill size themselves; a fixed length would only be right on a screen as wide as this one.
        for k in ("maximumLength", "minimumLength", "offset"):
          panel.pop(k, None)
    for applet in panel.get("applets", []):
      conf = applet.get("config", {})
      for plugin, group, key in panel_ignore():
        if applet.get("plugin") == plugin:
          conf.get(group, {}).pop(key, None)
      for g in PANEL_NOISE_GROUPS:
        conf.pop(g, None)
      for k in PANEL_NOISE_KEYS:
        conf.get("/", {}).pop(k, None)
      if "/" in conf and not conf["/"]:
        del conf["/"]
      colors = conf.get("/SensorColors")
      if colors:
        # System monitor widgets store a color per sensor a pattern matched (cpu/cpu0/usage for cpu/cpu.*/usage),
        # and the sensors differ per machine; the pattern's own color is what syncs (see expand_sensor_colors).
        patterns = [re.compile(k) for k in colors if any(c in k for c in "*+?[")]
        for k in [k for k in colors if not any(c in k for c in "*+?[")]:
          if any(pat.fullmatch(k) for pat in patterns):
            del colors[k]
  tray = plasma_script("""
    var out = {};
    panels().forEach(function (p) {
      p.widgets("org.kde.plasma.systemtray").forEach(function (t) {
        t.currentConfigGroup = ["General"];
        %s.forEach(function (k) { out[k] = t.readConfig(k, ""); });
      });
    });
    print(JSON.stringify(out));
  """ % json.dumps(list(SYSTRAY_KEYS)))
  tray = json.loads(tray or "{}")
  return {"panels": panels, "systray": {k: v for k, v in tray.items() if v}}


def expand_sensor_colors(panels):
  """Gives every CPU core of this machine the color of a cpu/cpu.*/... pattern, so all its bars share one color."""
  for panel in panels:
    for applet in panel.get("applets", []):
      colors = applet.get("config", {}).get("/SensorColors")
      for key, color in list((colors or {}).items()):
        if key.startswith("cpu/cpu.*/"):
          for i in range(os.cpu_count() or 1):
            colors.setdefault(key.replace("cpu.*", f"cpu{i}", 1), color)


def load_panels(data):
  """Replaces every panel with the ones in data (the format of dump_panels)."""
  data = json.loads(json.dumps(data))
  panels = data.get("panels", [])
  expand_sensor_colors(panels)
  # Create the panels and say which new panel is which (matched by where it sits).
  created = json.loads(plasma_script("""
    panels().forEach(function (p) { p.remove(); });
    var data = %s;
    loadSerializedLayout({ "serializationFormatVersion": "1", "desktops": [], "panels": data });
    var tray = %s;
    var left = panels();
    var ids = data.map(function (d) {
      for (var i = 0; i < left.length; i++) {
        if (left[i].location === d.location && left[i].alignment === d.alignment) {
          return left.splice(i, 1)[0].id;
        }
      }
      return -1;
    });
    panels().forEach(function (p) {
      p.widgets("org.kde.plasma.systemtray").forEach(function (t) {
        t.currentConfigGroup = ["General"];
        for (var k in tray) { t.writeConfig(k, tray[k]); }
        t.reloadConfig();
      });
    });
    print(JSON.stringify(ids));
  """ % (json.dumps(panels), json.dumps(data.get("systray", {})))) or "[]")
  # Then how each is shown. In a separate run: a screen set in the run that created the panel does not stick.
  views = [{"id": pid, "view": {k: v for k, v in p.get("view", {}).items() if k not in ("opacity", "thickness")},
            "thickness": p.get("view", {}).get("thickness")} for pid, p in zip(created, panels) if pid >= 0]
  current = json.loads(plasma_script("""
    var views = %s;
    views.forEach(function (v) {
      var p = panelById(v.id);
      for (var k in v.view) { p[k] = v.view[k]; }
      if (v.thickness) { p.height = v.thickness; }
    });
    print(JSON.stringify(views.map(function (v) { return panelById(v.id).opacity; })));
  """ % json.dumps(views)) or "[]")
  restart = False
  for v, now, p in zip(views, current, (p for pid, p in zip(created, panels) if pid >= 0)):
    wanted = p.get("view", {}).get("opacity", "adaptive")
    subprocess.run(["kwriteconfig6", "--file", "plasmashellrc", "--group", "PlasmaViews", "--group", f"Panel {v['id']}",
                    "--key", "panelOpacity", str(PANEL_OPACITY.get(wanted, 0))], check=False)
    restart |= wanted != now
  if THEMER_PANELS_JS.exists():
    plasma_script(THEMER_PANELS_JS.read_text())
  if restart:
    # Panels read their opacity only when plasmashell starts.
    subprocess.run(["systemctl", "--user", "restart", "plasma-plasmashell.service"], check=False)


def panels_text(data):
  return json.dumps(data, indent=2, sort_keys=True, ensure_ascii=False) + "\n"


def plasmashell_age():
  """Seconds since plasmashell started, None when it is not running."""
  res = subprocess.run(["pgrep", "-xo", "plasmashell"], capture_output=True, text=True)
  if not res.stdout.strip():
    return None
  try:
    stat = Path(f"/proc/{res.stdout.split()[0]}/stat").read_text()
    started = int(stat.rsplit(")", 1)[1].split()[19]) / os.sysconf("SC_CLK_TCK")
    return float(Path("/proc/uptime").read_text().split()[0]) - started
  except (OSError, ValueError, IndexError):
    return None


def sync_panels(dry_run):
  path = repo_dir() / PANELS_FILE
  state = STATE_DIR / "panels.json"
  age = plasmashell_age()
  if age is None or age < PLASMASHELL_SETTLE_S:
    # While plasmashell starts, it writes its files with only some panels loaded; a dump then would look like panels
    # were removed.
    print_info("panels skipped: plasmashell is not running or just started")
    return False
  try:
    live = panels_text(dump_panels())
  except (RuntimeError, ValueError) as e:
    print_warn(f"panels skipped: {e}")
    return False
  repo = path.read_text() if path.exists() else None
  base = state.read_text() if state.exists() else None
  if repo is None or live == repo:
    action = "save" if repo is None else None
  elif base == repo:
    action = "save"
  else:
    action = "apply"
    if base is not None and live != base:
      print_warn("panels changed here and in the dotfiles; the dotfiles win")
  if action:
    print_info(f"panels -> {'dotfiles (' + PANELS_FILE + ')' if action == 'save' else 'plasmashell'}")
  if dry_run:
    return bool(action)
  if action == "save":
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(live)
  elif action == "apply":
    load_panels(json.loads(repo))
  STATE_DIR.mkdir(parents=True, exist_ok=True)
  atomic_write(state, live if action != "apply" else repo)
  return bool(action)


# ==== Commands ====
def cmd_sync(args):
  cfg = load_config()
  files = cfg.get("files", {})
  names = args.names or list(files) + ([PANELS] if cfg.get("panels", {}).get("enabled") else [])
  STATE_DIR.mkdir(parents=True, exist_ok=True)
  with open(STATE_DIR / "lock", "w") as lock:
    fcntl.flock(lock, fcntl.LOCK_EX)
    changed = False
    for name in names:
      if name == PANELS:
        changed |= sync_panels(args.dry_run)
      elif name in files:
        changed |= sync_file(name, files[name], args.dry_run)
      else:
        print_error(f"{name} is not in {CONFIG}")
  if not changed and not QUIET:
    print_success("everything in sync")


def cmd_panels(args):
  STATE_DIR.mkdir(parents=True, exist_ok=True)
  path = repo_dir() / PANELS_FILE
  if args.action == "save":
    text = panels_text(dump_panels())
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    atomic_write(STATE_DIR / "panels.json", text)
    print_success(f"saved the panels to {path}")
  else:
    if not path.exists():
      die(f"{path} does not exist; run kde-sync panels save on the machine whose panels you want")
    load_panels(json.loads(path.read_text()))
    atomic_write(STATE_DIR / "panels.json", path.read_text())
    print_success("loaded the panels from the dotfiles")


def main():
  global QUIET
  ap = argparse.ArgumentParser(prog="kde-sync", description="Sync KDE settings through the dotfiles, key by key.")
  ap.add_argument("-q", "--quiet", action="store_true", help="only print warnings and errors")
  sub = ap.add_subparsers(dest="cmd", required=True)
  p = sub.add_parser("sync", help="sync the files in config.toml and the panels")
  p.add_argument("names", nargs="*", help="only these (file names, or 'panels')")
  p.add_argument("-n", "--dry-run", action="store_true", help="show what would change")
  p.set_defaults(fn=cmd_sync)
  p = sub.add_parser("status", help="what sync would change")
  p.set_defaults(fn=cmd_sync, names=[], dry_run=True)
  for name, to_host, helptext in (("local", True, "keep a key per machine"), ("share", False, "sync a key again")):
    p = sub.add_parser(name, help=helptext)
    p.add_argument("file")
    p.add_argument("group")
    p.add_argument("key")
    p.set_defaults(fn=lambda a, h=to_host: move_key(a.file, a.group, a.key, h))
  p = sub.add_parser("panels", help="save the panels to the dotfiles or load them from there")
  p.add_argument("action", choices=("save", "apply"))
  p.set_defaults(fn=cmd_panels)
  args = ap.parse_args()
  QUIET = args.quiet
  args.fn(args)


if __name__ == "__main__":
  main()
