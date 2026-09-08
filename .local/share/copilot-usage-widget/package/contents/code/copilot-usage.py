#!/usr/bin/env python3
"""Fetch GitHub Copilot quota (premium requests + chat/completions) from the
same internal endpoint the official `copilot` CLI itself calls
(`GET /copilot_internal/user`, Bearer auth). Reads the default profile
(~/.copilot) unless install.sh was given a custom COPILOT_HOME directory, in
which case it reads only that one. Emits compact JSON for the Plasma widget,
with the reset date pre-converted to epoch milliseconds.
"""
import json
import os
import datetime
import urllib.request
import urllib.error

# install.sh writes this marker file when given a custom COPILOT_HOME
# argument, and removes it when run with no argument (default profile).
HOME_OVERRIDE_FILE = os.path.expanduser(
    "~/.config/copilot-usage-widget/copilot_home")


def resolve_copilot_home():
    # COPILOT_USAGE_CONFIG is a full override (config.json's own path) for
    # advanced/manual use; skip the marker file and default entirely.
    override = os.environ.get("COPILOT_USAGE_CONFIG")
    if override:
        return os.path.dirname(os.path.expanduser(override)) or "."
    try:
        with open(HOME_OVERRIDE_FILE) as f:
            custom = f.read().strip()
        if custom:
            return os.path.expanduser(custom)
    except Exception:
        pass
    return os.path.expanduser("~/.copilot")


COPILOT_HOME = resolve_copilot_home()
CONFIG = os.environ.get("COPILOT_USAGE_CONFIG") or os.path.join(COPILOT_HOME, "config.json")
CONFIG = os.path.expanduser(CONFIG)


def emit(obj):
    obj["fetched_ms"] = int(datetime.datetime.now().timestamp() * 1000)
    obj["copilot_home"] = COPILOT_HOME
    print(json.dumps(obj))
    raise SystemExit(0)


def strip_json_comments(text):
    # config.json ships with a couple of leading `//` comment lines.
    return "\n".join(l for l in text.splitlines() if not l.strip().startswith("//"))


try:
    with open(CONFIG) as f:
        cfg = json.loads(strip_json_comments(f.read()))
    tokens = cfg.get("copilotTokens") or {}
    # Prefer the token matching config.json's own idea of who's logged in;
    # config.json normally holds exactly one entry anyway.
    preferred_login = (cfg.get("lastLoggedInUser") or {}).get("login")
    token = None
    if preferred_login:
        for key, val in tokens.items():
            if key.endswith(":" + preferred_login):
                token = val
                break
    if token is None and tokens:
        token = next(iter(tokens.values()))
    if not token:
        raise ValueError("no token")
except Exception:
    emit({"error": "no-token"})

req = urllib.request.Request(
    "https://api.github.com/copilot_internal/user",
    headers={"Authorization": "Bearer " + token, "Accept": "application/json"},
)
try:
    with urllib.request.urlopen(req, timeout=10) as r:
        data = json.load(r)
except urllib.error.HTTPError as e:
    emit({"error": "http-%d" % e.code})  # 401 => token expired/revoked
except Exception:
    emit({"error": "net"})


def to_ms(date_str):
    if not date_str:
        return None
    try:
        # comes back either as a bare date ("2026-10-01") or a full ISO
        # timestamp ("2026-10-01T00:00:00.000Z")
        if len(date_str) <= 10:
            dt = datetime.datetime.fromisoformat(date_str + "T00:00:00+00:00")
        else:
            dt = datetime.datetime.fromisoformat(date_str.replace("Z", "+00:00"))
        return int(dt.timestamp() * 1000)
    except Exception:
        return None


LABELS = {
    "premium_interactions": "Premium requests",
    "chat": "Chat",
    "completions": "Completions",
}

reset_ms = to_ms(data.get("quota_reset_date_utc") or data.get("quota_reset_date"))

snapshots = data.get("quota_snapshots") or {}
quotas = []
for key in ("premium_interactions", "chat", "completions"):
    snap = snapshots.get(key)
    if not snap:
        continue
    unlimited = bool(snap.get("unlimited"))
    pct_remaining = snap.get("percent_remaining")
    util = None if unlimited or pct_remaining is None else max(0.0, 100.0 - pct_remaining)
    quotas.append({
        "kind": key,
        "label": LABELS.get(key, key.replace("_", " ").title()),
        "unlimited": unlimited,
        "util": util,
        "entitlement": snap.get("entitlement"),
        "remaining": snap.get("remaining"),
    })

emit({
    "ok": True,
    "plan": data.get("copilot_plan"),
    "login": (cfg.get("lastLoggedInUser") or {}).get("login"),
    "reset_ms": reset_ms,
    "quotas": quotas,
})
