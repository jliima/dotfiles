#!/usr/bin/env python3
"""Fetch Claude's usage limits from the OAuth usage endpoint, the source of Claude Code's /usage, with the token
Claude Code keeps in ~/.claude/.credentials.json. Prints one line of JSON for the Plasma widget:

  {"ok": true, "session": {"util": 15, "resets_ms": ...}, "weekly": {...}, "limits": [...], "fetched_ms": ...}

or {"error": "no-token" | "http-401" | "http-429" | "net", "fetched_ms": ...}. Reset times are epoch milliseconds.
"""
import datetime
import json
import os
import urllib.error
import urllib.request

CREDENTIALS = os.path.expanduser(os.environ.get("CLAUDE_CREDENTIALS", "~/.claude/.credentials.json"))
URL = "https://api.anthropic.com/api/oauth/usage"


def emit(obj):
  obj["fetched_ms"] = int(datetime.datetime.now().timestamp() * 1000)
  print(json.dumps(obj))
  raise SystemExit(0)


def to_ms(iso):
  try:
    return int(datetime.datetime.fromisoformat(iso).timestamp() * 1000) if iso else None
  except ValueError:
    return None


def window(d):
  return {"util": d.get("utilization"), "resets_ms": to_ms(d.get("resets_at"))} if d else None


try:
  with open(CREDENTIALS) as f:
    token = json.load(f)["claudeAiOauth"]["accessToken"]
except (OSError, KeyError, ValueError):
  emit({"error": "no-token"})

req = urllib.request.Request(URL, headers={"Authorization": "Bearer " + token, "anthropic-beta": "oauth-2025-04-20"})
try:
  with urllib.request.urlopen(req, timeout=10) as r:
    data = json.load(r)
except urllib.error.HTTPError as e:
  emit({"error": "http-%d" % e.code})
except (OSError, ValueError):
  emit({"error": "net"})

# Per-model weekly caps only come in the `limits` array.
limits = []
for lim in data.get("limits") or []:
  if not isinstance(lim, dict) or lim.get("kind") in ("session", "weekly_all"):
    continue
  scope = lim.get("scope") or {}
  label = (scope.get("model") or {}).get("display_name") or (lim.get("kind") or "limit").replace("_", " ").title()
  limits.append({"label": label, "util": lim.get("percent"), "resets_ms": to_ms(lim.get("resets_at"))})

emit({"ok": True, "session": window(data.get("five_hour")), "weekly": window(data.get("seven_day")),
      "limits": limits})
