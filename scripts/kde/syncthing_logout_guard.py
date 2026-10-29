#!/usr/bin/env python3

# ------------------------------------------------------------------------------
#
# Name:        syncthing_logout_guard.py
#
# Description: Hold a Plasma logout, shutdown or reboot until Syncthing has sent
#              every folder to the other devices.
#
# Details:
# Runs in the background for the whole session as an X11 session management
# (XSMP) client of ksmserver. Qt only speaks XSMP on the xcb platform, so the
# program always runs through XWayland. When the session ends, ksmserver asks
# every client to save; this program asks for an interaction turn, which makes
# ksmserver wait, and shows a window while it:
#
#   1. starts a scan of every unpaused folder (the folders may scan only hourly)
#   2. waits until each connected device that shares the folder has everything
#      (completion 100 %), shown per folder with scan and upload progress
#
# When all folders are done the window closes and the logout continues. If the
# server is offline, a device stops taking data without catching up, or files
# could not be read (a running VM's disk changes while it is hashed), the window
# counts down and then continues anyway. The buttons skip the wait or cancel the
# logout.
#
# Only logouts that go through ksmserver are held (the Plasma menu, the logout
# screen, the power button). "systemctl poweroff" in a terminal is not.
#
# Usage:
#   syncthing_logout_guard.py                 run as the session guard (autostart)
#   syncthing_logout_guard.py --now           sync every folder now, in the same window
#   syncthing_logout_guard.py --test-cancel   guard that cancels the logout after syncing
#
# Log: ~/.cache/syncthing-logout-guard/guard.log
#
# Dependencies: python3-pyqt6, Syncthing with its GUI/REST API enabled
#
# ------------------------------------------------------------------------------

from __future__ import annotations

import argparse
import configparser
import json
import logging
import os
import ssl
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from pathlib import Path

# Qt has XSMP support only on xcb; set before Qt is imported.
os.environ["QT_QPA_PLATFORM"] = "xcb"

from PyQt6.QtCore import QEventLoop, QLockFile, Qt, QTimer, pyqtSignal  # noqa: E402
from PyQt6.QtGui import QColor, QFont, QPalette, QSessionManager  # noqa: E402
from PyQt6.QtWidgets import (  # noqa: E402
  QApplication,
  QFrame,
  QGridLayout,
  QHBoxLayout,
  QLabel,
  QProgressBar,
  QPushButton,
  QScrollArea,
  QVBoxLayout,
  QWidget,
)

# ==== Configuration ====

SYNCTHING_CONFIG = Path.home() / ".local/state/syncthing/config.xml"
# The hub every folder goes through; when it is offline nothing can be sent.
SERVER_DEVICE_PREFIX = "U5PWWG7"
POLL_INTERVAL_S = 1.5
# A device that is not connected yet gets this long to come back (e.g. after a resume).
OFFLINE_GRACE_S = 10
# Polls in a row that must show a folder complete before it counts as done.
STABLE_POLLS = 2
DONE_CLOSE_DELAY_MS = 1500
OFFLINE_COUNTDOWN_S = 30
# A device that is behind but received no data and made no progress for this long counts as stalled
# (e.g. a version conflict it never resolves). Long enough for the server to rebuild a big file from
# blocks it already has, which sends nothing over the network.
STALL_S = 120
STALL_MIN_BYTES = 64 * 1024
LOG_DIR = Path.home() / ".cache/syncthing-logout-guard"
HTTP_TIMEOUT_S = 10

log = logging.getLogger("guard")

# ==== Syncthing REST client ====


class Syncthing:
  """Minimal client for the local Syncthing REST API."""

  def __init__(self, config_path: Path) -> None:
    root = ET.parse(config_path).getroot()
    gui = root.find("gui")
    if gui is None:
      raise RuntimeError(f"no <gui> section in {config_path}")
    address = gui.findtext("address", "127.0.0.1:8384")
    scheme = "https" if gui.get("tls", "false") == "true" else "http"
    self.base = f"{scheme}://{address.replace('0.0.0.0', '127.0.0.1')}"
    self.key = gui.findtext("apikey", "")
    self.ctx = ssl.create_default_context()
    self.ctx.check_hostname = False
    self.ctx.verify_mode = ssl.CERT_NONE

  def call(self, path: str, method: str = "GET", http_timeout: float = HTTP_TIMEOUT_S, **params: str):
    url = f"{self.base}{path}"
    if params:
      url += "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, method=method, headers={"X-API-Key": self.key})
    with urllib.request.urlopen(req, context=self.ctx, timeout=http_timeout) as resp:
      body = resp.read()
    return json.loads(body) if body.strip() else None


# ==== Sync state ====


@dataclass
class FolderRow:
  """What the window shows for one folder."""

  id: str
  label: str
  peers: list[str]
  scanned: bool = False
  scan_error: str = ""
  scan_pct: float | None = None
  state: str = "pending"  # pending, scanning, sending, done, skipped, offline, stalled, partial, error
  detail: str = "Waiting"
  progress: float = 0.0
  stable: int = 0


@dataclass
class Snapshot:
  rows: list[FolderRow] = field(default_factory=list)
  fatal: str = ""
  started: bool = False


class Syncer:
  """Scans every folder and tracks until the connected devices have it all, in background threads."""

  def __init__(self) -> None:
    self.lock = threading.Lock()
    self.snap = Snapshot()
    self.stop = threading.Event()
    self.started_at = time.monotonic()
    self.names: dict[str, str] = {}
    self.server_id = ""
    # device -> (bytes sent to it, when that last grew); folder -> (completion, bytes left, when that last changed)
    self.traffic: dict[str, tuple[int, float]] = {}
    self.progress: dict[str, tuple[float, int, float]] = {}

  def start(self) -> None:
    threading.Thread(target=self._run, daemon=True).start()

  def snapshot(self) -> Snapshot:
    with self.lock:
      return Snapshot([FolderRow(**vars(r)) for r in self.snap.rows], self.snap.fatal, self.snap.started)

  def _run(self) -> None:
    try:
      self.st = Syncthing(SYNCTHING_CONFIG)
      my_id = self.st.call("/rest/system/status")["myID"]
      self.names = {d["deviceID"]: d["name"] or d["deviceID"][:7] for d in self.st.call("/rest/config/devices")}
      self.server_id = next((d for d in self.names if d.startswith(SERVER_DEVICE_PREFIX)), "")
      folders = [f for f in self.st.call("/rest/config/folders") if not f["paused"]]
    except (OSError, RuntimeError, ET.ParseError, KeyError, ValueError) as e:
      log.error("syncthing unreachable: %s", e)
      with self.lock:
        self.snap.fatal = f"Syncthing is not reachable ({e})"
      return
    rows = [
      FolderRow(f["id"], f["label"] or f["id"], [d["deviceID"] for d in f["devices"] if d["deviceID"] != my_id])
      for f in folders
    ]
    with self.lock:
      self.snap.rows = rows
      self.snap.started = True
    log.info("syncing %d folders", len(rows))
    for row in rows:
      threading.Thread(target=self._scan, args=(row.id,), daemon=True).start()
    threading.Thread(target=self._scan_progress, daemon=True).start()
    # Polls until the window closes, so an offline or stalled folder can still recover during the countdown.
    while not self.stop.is_set():
      try:
        self._poll()
      except (OSError, ValueError, KeyError) as e:
        log.warning("poll failed: %s", e)
      self.stop.wait(POLL_INTERVAL_S)

  def _scan(self, folder: str) -> None:
    # POST /rest/db/scan returns when the scan is finished; a large VM disk can take minutes.
    err = ""
    try:
      self.st.call("/rest/db/scan", "POST", http_timeout=3600, folder=folder)
    except urllib.error.HTTPError as e:
      err = e.read().decode(errors="replace").strip() or str(e)
    except OSError as e:
      err = str(e)
    with self.lock:
      for r in self.snap.rows:
        if r.id == folder:
          r.scanned, r.scan_error = True, err
    if err:
      log.warning("scan of %s failed: %s", folder, err)

  def _scan_progress(self) -> None:
    since = 0
    try:
      since = self.st.call("/rest/events", events="FolderScanProgress", since="0", limit="1", timeout="0")
      since = since[-1]["id"] if since else 0
    except (OSError, ValueError):
      pass
    while not self.stop.is_set():
      try:
        events = self.st.call("/rest/events", http_timeout=15, events="FolderScanProgress", since=str(since),
                                timeout="10") or []
      except (OSError, ValueError):
        self.stop.wait(2)
        continue
      with self.lock:
        for ev in events:
          since = max(since, ev["id"])
          data = ev["data"]
          for r in self.snap.rows:
            if r.id == data["folder"] and data.get("total"):
              r.scan_pct = 100.0 * data["current"] / data["total"]

  def _poll(self) -> None:
    conns = self.st.call("/rest/system/connections")["connections"]
    now = time.monotonic()
    for dev, c in conns.items():
      sent = c.get("outBytesTotal", 0)
      prev = self.traffic.get(dev)
      if prev is None or sent - prev[0] > STALL_MIN_BYTES:
        self.traffic[dev] = (sent, now)
    in_grace = time.monotonic() - self.started_at < OFFLINE_GRACE_S
    with self.lock:
      rows = [(r.id, list(r.peers), r.scanned, r.scan_error, r.scan_pct) for r in self.snap.rows]
    for fid, peers, scanned, scan_error, scan_pct in rows:
      status = self.st.call("/rest/db/status", folder=fid)
      upd: dict = {}
      if status.get("state") == "error" or scan_error:
        upd = {"state": "error", "detail": scan_error or status.get("error") or "Folder error"}
      elif not scanned or status.get("state") in ("scanning", "scan-waiting"):
        pct = f" {scan_pct:.0f} %" if scan_pct is not None and status.get("state") == "scanning" else ""
        waiting = status.get("state") == "scan-waiting"
        upd = {"state": "scanning", "detail": "Waiting to scan" if waiting else f"Scanning{pct}",
               "progress": (scan_pct or 0) * 0.5}
      else:
        upd = self._peer_state(fid, peers, conns, in_grace)
        if upd["state"] == "done" and status.get("pullErrors"):
          upd = self._file_errors(fid, status["pullErrors"])
      with self.lock:
        for r in self.snap.rows:
          if r.id != fid:
            continue
          if upd.get("state") == "done":
            r.stable += 1
            if r.stable < STABLE_POLLS:
              upd = {**upd, "state": "sending", "detail": "Checking"}
          else:
            r.stable = 0
          if r.state != upd["state"]:
            log.info("%s: %s (%s)", r.label, upd["state"], upd["detail"])
          for k, v in upd.items():
            setattr(r, k, v)

  def _file_errors(self, fid: str, count: int) -> dict:
    # Files that failed to hash (a running VM's disk) keep their old version in the index, so the devices look
    # complete while the file on disk is newer.
    errors = (self.st.call("/rest/folder/errors", folder=fid) or {}).get("errors") or []
    first = f": {Path(errors[0]['path']).name} ({errors[0]['error']})" if errors else ""
    return {"state": "partial", "detail": f"{count} file(s) not sent{first}", "progress": 100}

  def _peer_state(self, fid: str, peers: list[str], conns: dict, in_grace: bool) -> dict:
    online = [p for p in peers if conns.get(p, {}).get("connected")]
    offline = [self.names.get(p, p[:7]) for p in peers if p not in online]
    waiting: list[str] = []
    waiting_ids: list[str] = []
    lowest = 100.0
    left = 0
    for p in online:
      c = self.st.call("/rest/db/completion", folder=fid, device=p)
      if c.get("remoteState", "valid") != "valid":
        continue
      if c["completion"] < 100 or c.get("needItems", 0) or c.get("needDeletes", 0):
        waiting.append(self.names.get(p, p[:7]))
        waiting_ids.append(p)
        lowest = min(lowest, c["completion"])
        left += c.get("needBytes", 0)
    if waiting:
      now = time.monotonic()
      prev = self.progress.get(fid)
      if prev is None or prev[:2] != (lowest, left):
        self.progress[fid] = (lowest, left, now)
      last_moved = max([self.progress[fid][2]] + [self.traffic.get(d, (0, now))[1] for d in waiting_ids])
      where = f"{', '.join(waiting)}: {lowest:.0f} %, {human(left)} left"
      if now - last_moved > STALL_S:
        return {"state": "stalled", "detail": f"Stalled, nothing moving ({where})", "progress": 50 + lowest / 2}
      return {"state": "sending", "detail": f"Sending to {where}", "progress": 50 + lowest / 2}
    if offline and in_grace:
      return {"state": "sending", "detail": f"Waiting for {', '.join(offline)} to connect", "progress": 50}
    server_offline = self.server_id in peers and self.server_id not in online
    if server_offline:
      return {"state": "offline", "detail": f"Not sent: {self.names[self.server_id]} is offline", "progress": 100}
    if not online:
      return {"state": "skipped", "detail": f"Skipped: {', '.join(offline)} offline", "progress": 100}
    detail = "Up to date" + (f" ({', '.join(offline)} offline)" if offline else "")
    return {"state": "done", "detail": detail, "progress": 100}


def human(n: float) -> str:
  for unit in ("B", "KB", "MB", "GB"):
    if n < 1024:
      return f"{n:.0f} {unit}" if unit == "B" else f"{n:.1f} {unit}"
    n /= 1024
  return f"{n:.1f} TB"


# ==== Window ====


def kde_colors(palette: QPalette) -> dict[str, QColor]:
  """Status colours from the Plasma colour scheme (Themer writes it), the Qt palette as fallback."""
  colors = {
    "positive": QColor(48, 218, 151),
    "neutral": QColor(245, 141, 49),
    "negative": QColor(244, 89, 89),
    "active": palette.color(QPalette.ColorRole.Highlight),
    "inactive": palette.color(QPalette.ColorRole.PlaceholderText),
  }
  cfg = configparser.ConfigParser(interpolation=None, strict=False)
  try:
    cfg.read(Path.home() / ".config/kdeglobals")
    sect = cfg["Colors:Window"]
    for name, key in (("positive", "ForegroundPositive"), ("neutral", "ForegroundNeutral"),
                      ("negative", "ForegroundNegative"), ("active", "ForegroundActive"),
                      ("inactive", "ForegroundInactive")):
      if key in sect:
        colors[name] = QColor(*(int(v) for v in sect[key].split(",")[:3]))
  except (KeyError, ValueError, configparser.Error):
    pass
  return colors


GLYPHS = {"pending": "·", "scanning": "⟳", "sending": "↑", "done": "✓", "skipped": "–", "offline": "!",
          "stalled": "!", "partial": "!", "error": "✗"}
ROLE = {"pending": "inactive", "scanning": "active", "sending": "active", "done": "positive", "skipped": "inactive",
        "offline": "neutral", "stalled": "neutral", "partial": "neutral", "error": "negative"}


class SyncWindow(QWidget):
  """Progress window; emits finished(proceed) when the session may end (True) or the user cancelled (False)."""

  finished = pyqtSignal(bool)

  def __init__(self, during_logout: bool) -> None:
    super().__init__(None, Qt.WindowType.Window | Qt.WindowType.WindowStaysOnTopHint)
    self.during_logout = during_logout
    self.syncer = Syncer()
    self.colors = kde_colors(self.palette())
    self.rows: dict[str, tuple[QLabel, QLabel, QLabel]] = {}
    self.deadline: float | None = None
    self.closing = False
    self.setWindowTitle("Syncthing: syncing before logout" if during_logout else "Syncthing: syncing")
    self.resize(620, 560)

    title = QLabel("Syncing before the session ends" if during_logout else "Syncing every folder")
    f = QFont(title.font())
    f.setPointSizeF(f.pointSizeF() * 1.5)
    f.setBold(True)
    title.setFont(f)
    self.subtitle = QLabel("Starting Syncthing scans…")
    self.subtitle.setWordWrap(True)
    self.bar = QProgressBar()
    self.bar.setRange(0, 1000)
    self.bar.setTextVisible(False)

    self.grid = QGridLayout()
    self.grid.setColumnStretch(1, 1)
    self.grid.setHorizontalSpacing(12)
    inner = QWidget()
    inner_layout = QVBoxLayout(inner)
    inner_layout.addLayout(self.grid)
    inner_layout.addStretch(1)
    scroll = QScrollArea()
    scroll.setWidgetResizable(True)
    scroll.setFrameShape(QFrame.Shape.NoFrame)
    scroll.setWidget(inner)

    self.skip_btn = QPushButton("Continue without waiting" if during_logout else "Close")
    self.skip_btn.clicked.connect(lambda: self._finish(True, "skipped by the user"))
    self.cancel_btn = QPushButton("Cancel logout")
    self.cancel_btn.clicked.connect(lambda: self._finish(False, "logout cancelled by the user"))
    self.cancel_btn.setVisible(during_logout)
    buttons = QHBoxLayout()
    buttons.addStretch(1)
    buttons.addWidget(self.cancel_btn)
    buttons.addWidget(self.skip_btn)

    layout = QVBoxLayout(self)
    layout.setContentsMargins(20, 18, 20, 16)
    layout.setSpacing(10)
    layout.addWidget(title)
    layout.addWidget(self.subtitle)
    layout.addWidget(self.bar)
    layout.addWidget(scroll, 1)
    layout.addLayout(buttons)

    self.timer = QTimer(self)
    self.timer.timeout.connect(self._refresh)

  def start(self) -> None:
    self.syncer.start()
    self.timer.start(300)
    self.show()
    self.raise_()
    self.activateWindow()

  def _row(self, r: FolderRow) -> tuple[QLabel, QLabel, QLabel]:
    if r.id not in self.rows:
      n = len(self.rows)
      glyph, name, detail = QLabel(), QLabel(r.label), QLabel()
      glyph.setFixedWidth(18)
      glyph.setAlignment(Qt.AlignmentFlag.AlignCenter)
      detail.setAlignment(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter)
      self.grid.addWidget(glyph, n, 0)
      self.grid.addWidget(name, n, 1)
      self.grid.addWidget(detail, n, 2)
      self.rows[r.id] = (glyph, name, detail)
    return self.rows[r.id]

  def _refresh(self) -> None:
    snap = self.syncer.snapshot()
    if snap.fatal:
      self.subtitle.setText(snap.fatal)
      self._start_countdown()
      self._tick_countdown()
      return
    if not snap.started:
      return
    for r in snap.rows:
      glyph, name, detail = self._row(r)
      color = self.colors[ROLE[r.state]].name()
      glyph.setText(GLYPHS[r.state])
      glyph.setStyleSheet(f"color: {color}; font-weight: bold;")
      detail.setText(r.detail)
      detail.setStyleSheet(f"color: {color};" if r.state in ("offline", "stalled", "partial", "error") else "")
      dim = r.state in ("done", "skipped")
      name.setStyleSheet(f"color: {self.colors['inactive'].name()};" if dim else "")
    total = len(snap.rows) or 1
    self.bar.setValue(int(10 * sum(r.progress for r in snap.rows) / total))
    busy = [r for r in snap.rows if r.state in ("pending", "scanning", "sending")]
    problems = [r for r in snap.rows if r.state in ("offline", "stalled", "partial", "error")]
    if busy:
      self.deadline = None
      self.subtitle.setText(f"Waiting for {len(busy)} of {total} folders. "
                            + ("The session ends when they are sent." if self.during_logout else ""))
      return
    if not problems:
      self.subtitle.setText("Everything is sent.")
      self.bar.setValue(1000)
      self._finish(True, "all folders synced", delay=DONE_CLOSE_DELAY_MS)
      return
    self._start_countdown()
    self._tick_countdown(f"{len(problems)} folder(s) could not be sent.")

  def _start_countdown(self) -> None:
    if self.deadline is None:
      self.deadline = time.monotonic() + OFFLINE_COUNTDOWN_S

  def _tick_countdown(self, prefix: str = "") -> None:
    if self.closing:
      return
    secs = max(0, round(self.deadline - time.monotonic()))
    what = "Continuing" if self.during_logout else "Closing"
    self.subtitle.setText(f"{prefix} {what} in {secs} s.".strip())
    if secs <= 0:
      self._finish(True, f"continued after the countdown ({prefix or self.subtitle.text()})")

  def _finish(self, proceed: bool, why: str, delay: int = 0) -> None:
    if self.closing:
      return
    self.closing = True
    log.info("finished: %s", why)
    self.syncer.stop.set()
    self.skip_btn.setEnabled(False)
    self.cancel_btn.setEnabled(False)

    def done() -> None:
      self.timer.stop()
      self.hide()
      self.finished.emit(proceed)

    QTimer.singleShot(delay, done)

  def closeEvent(self, event) -> None:  # noqa: N802 (Qt override)
    # Closing the window by its title bar button is "continue without waiting".
    if not self.closing:
      self._finish(True, "window closed by the user")
    event.accept()


# ==== Session management ====


class Guard:
  """XSMP client that holds the session end while a SyncWindow runs."""

  def __init__(self, app: QApplication, test_cancel: bool) -> None:
    self.app = app
    self.test_cancel = test_cancel
    app.commitDataRequest.connect(self.commit_data)
    app.saveStateRequest.connect(self.save_state)

  @staticmethod
  def save_state(sm: QSessionManager) -> None:
    # Autostart starts the guard; ksmserver must not restore a second copy.
    log.info("session save requested")
    sm.setRestartHint(QSessionManager.RestartHint.RestartNever)

  def commit_data(self, sm: QSessionManager) -> None:
    sm.setRestartHint(QSessionManager.RestartHint.RestartNever)
    log.info("session end requested")
    if not sm.allowsInteraction():
      log.warning("ksmserver did not allow interaction, not holding the session end")
      return
    window = SyncWindow(during_logout=True)
    loop = QEventLoop()
    result = {"proceed": True}

    def on_finished(proceed: bool) -> None:
      result["proceed"] = proceed
      loop.quit()

    window.finished.connect(on_finished)
    window.start()
    loop.exec()
    window.deleteLater()
    if not result["proceed"] or self.test_cancel:
      log.info("cancelling the session end%s", " (--test-cancel)" if result["proceed"] else "")
      sm.cancel()
    sm.release()


# ==== Main ====


def main() -> int:
  parser = argparse.ArgumentParser(description="Hold a Plasma logout until Syncthing has sent every folder.")
  parser.add_argument("--now", action="store_true", help="sync every folder now and show the progress window")
  parser.add_argument("--test-cancel", action="store_true", help="cancel the logout after syncing (for testing)")
  args = parser.parse_args()

  LOG_DIR.mkdir(parents=True, exist_ok=True)
  logging.basicConfig(filename=LOG_DIR / "guard.log", level=logging.INFO,
                      format="%(asctime)s %(levelname)s %(message)s")
  app = QApplication(sys.argv)
  app.setApplicationName("syncthing-logout-guard")
  app.setDesktopFileName("syncthing-logout-guard")

  if args.now:
    window = SyncWindow(during_logout=False)
    window.finished.connect(lambda _: app.quit())
    window.start()
    return app.exec()

  lock = QLockFile(str(Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "syncthing-logout-guard.lock"))
  if not lock.tryLock(0):
    print("syncthing-logout-guard is already running", file=sys.stderr)
    return 0
  if not app.sessionId():
    log.warning("not connected to a session manager (SESSION_MANAGER unset?), logouts will not be held")
  log.info("guard started, session id %s, pid %d", app.sessionId(), os.getpid())
  app.setQuitOnLastWindowClosed(False)
  _guard = Guard(app, args.test_cancel)
  return app.exec()


if __name__ == "__main__":
  sys.exit(main())
