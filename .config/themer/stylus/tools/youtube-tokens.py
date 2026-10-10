#!/usr/bin/env python3
# youtube-tokens.py: rewrites the generated token block of ../youtube.user.css from YouTube's live stylesheet.
#
# YouTube's components do not read --yt-sys-color-baseline--* but a hashed copy of each token (--t3e41d7b17b187f69 is
# the base background), declared in its main stylesheet with the literal colors of the dark and the light set. The
# hashed names are generated when YouTube builds its CSS, so they may change when it ships a new build. This script
# downloads the current stylesheet, finds for every hashed variable the tokens with the same dark and light colors,
# and writes `--hash: var(--themer-...) !important` for each one the table below maps. The unhashed names are written
# too (the few parts of the page that still use them).
#
#   youtube-tokens.py                    update ../youtube.user.css in place
#   youtube-tokens.py --css FILE         read the stylesheet from FILE instead of downloading it
#   youtube-tokens.py --print            show the block instead of writing it
#
# When YouTube's colors come back after a while, run this once and reload the page.
import argparse
import re
import sys
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
USERCSS = HERE.parent / "youtube.user.css"
BEGIN, END = "/* BEGIN generated tokens */", "/* END generated tokens */"
UA = "Mozilla/5.0 (X11; Linux x86_64; rv:151.0) Gecko/20100101 Firefox/151.0"

# YouTube's token (without --yt-sys-color-baseline--) -> the Themer token, or a CSS expression. Grounds like the rest
# of the desktop: pages bg, cards surface, menus surface-raised; text-primary is text-bright, secondary text-muted.
# Tokens that are not here (the player's overlay colors, static whites and blacks, add-on hues) keep YouTube's value.
MAP = {
  # grounds
  "base-background": "bg",
  "raised-background": "surface",
  "surface-container": "surface",
  "menu-background": "surface-raised",
  "status-bar": "bg",
  "system-bar": "bg",
  "frosted-glass-desktop": "rgb(from var(--themer-bg) r g b / 0.85)",
  "frosted-glass-mobile": "rgb(from var(--themer-bg) r g b / 0.85)",
  # text
  "text-primary": "text-bright",
  "text-secondary": "text-muted",
  "text-disabled": "text-disabled",
  "text-primary-inverse": "bg",
  "text-secondary-inverse": "text-subtle",
  "text-disabled-inverse": "text-subtle",
  "wordmark-text": "text-bright",
  # filled mono controls (the Subscribe button, the selected chip) are the light-on-dark ones
  "inverted-background": "text-bright",
  "inverted-background-hover": "text",
  "solid-background": "surface-hover",
  "solid-background-inverse": "text-bright",
  "mono-filled-hover": "text",
  "mono-filled-hover-inverse": "surface-active",
  "filled-hover-light": "text",
  "filled-touch-light": "text-muted",
  "filled-state-layer": "text-muted",
  "touch-response": "text",
  "touch-response-inverse": "bg",
  # tonal layers and hovers
  "additive-background": "surface-hover",
  "additive-background-inverse": "surface-hover",
  "tonal-background": "surface-hover",
  "tonal-background-inverse": "surface-hover",
  "button-chip-background-hover": "surface-active",
  "mono-tonal-hover": "surface-active",
  "mono-tonal-hover-inverse": "surface-active",
  "tonal-hover-light": "surface-active",
  "tonal-touch-light": "surface-active",
  "tonal-state-layer": "surface-active",
  "tonal-wash": "surface",
  "tonal-wash-inverse": "surface",
  "solid-wash": "surface-hover",
  "solid-wash-inverse": "surface-hover",
  # lines
  "outline": "line",
  "outline-inverse": "line",
  "outline-opaque": "line",
  "outline-inverse-opaque": "line",
  "outline-rim": "line",
  "outline-rim-inverse": "line",
  "outline-wash": "line",
  "solid-rim": "line",
  "solid-rim-inverse": "line",
  "tonal-rim": "line",
  "tonal-rim-inverse": "line",
  # accent and status
  "call-to-action": "accent",
  "call-to-action-hover": "accent-hover",
  "call-to-action-inverse": "accent",
  "suggested-action": "accent-soft",
  "suggested-action-hover": "surface-hover",
  "suggested-action-inverse": "accent-soft",
  "themed-green": "success",
  "themed-green-inverse": "success",
  "text-complete": "success",
  "background-complete": "success-soft",
  "error-indicator": "danger",
  "error-indicator-inverse": "danger",
  "text-error": "danger",
  "error-background-red": "danger-soft",
  "text-warning": "warning",
  "background-warning": "warning-soft",
  "icon-warning": "warning",
  "brand-red-contrast": "red",
  "static-brand-red": "red",
  "red-3": "red",
}


def themer(value: str) -> str:
  return value if value.startswith("rgb(") else f"var(--themer-{value})"


def tint(literal: str, dark: bool) -> str | None:
  """A translucent white (dark mode) or black (light mode) layer stays a layer, tinted with the theme's text color,
  so hovers, washes and rims keep their strength. Other translucent colors keep YouTube's own value."""
  match = re.fullmatch(r"rgba\((\d+),\s*(\d+),\s*(\d+),\s*([0-9.]+)\)", literal.replace(" ", ""))
  if not match:
    return None
  red, green, blue, alpha = int(match[1]), int(match[2]), int(match[3]), match[4]
  if (dark and min(red, green, blue) >= 200) or (not dark and max(red, green, blue) <= 60):
    return f"rgb(from var(--themer-text) r g b / {alpha})"
  return None


def declaration(short: str, literal: str | None, dark: bool) -> str | None:
  """The value for one token in the dark or the light block, from YouTube's color in that mode."""
  if short in MAP and MAP[short].startswith("rgb("):
    return MAP[short]
  if literal is None:
    return None
  if literal.startswith("rgba("):
    return tint(literal, dark)
  return themer(MAP[short]) if short in MAP else None


def fetch_css() -> str:
  def get(url: str) -> str:
    # the Cookie skips YouTube's consent page
    headers = {"User-Agent": UA, "Cookie": "SOCS=CAESEwgDEgk0ODE3Nzk3MjQaAmVuIAEaBgiA_LyaBg"}
    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=60) as response:
      return response.read().decode("utf-8", "replace")
  page = get("https://www.youtube.com/results?search_query=x")
  match = re.search(r'https://www\.youtube\.com/s/_/ytmainappweb/_/ss/k=ytmainappweb\.kevlar_base[^"\'\\ <>]*', page)
  if not match:
    sys.exit("youtube-tokens: the main stylesheet (kevlar_base) is not linked from the page any more")
  return get(match.group(0))


def declarations(body: str) -> dict[str, str]:
  out = {}
  for item in body.split(";"):
    if ":" in item:
      key, value = item.split(":", 1)
      out[key.strip()] = value.strip()
  return out


def read_tokens(css: str):
  """The hashed variables with their (dark, light) colors, and the named tokens the same way."""
  dark_h, light_h, root_h, sys_d, sys_l = {}, {}, {}, {}, {}
  hashed = re.compile(r"--t[0-9a-f]{16}")
  for match in re.finditer(r"([^{}]+)\{([^{}]*)\}", css):
    selector, body = match.group(1).strip(), match.group(2)
    if "--t" not in body and "--yt-sys-color-baseline--" not in body:
      continue
    values = declarations(body)
    if selector == "[dark]":
      dark_h.update({k: v for k, v in values.items() if hashed.fullmatch(k)})
    elif selector == "[light]":
      light_h.update({k: v for k, v in values.items() if hashed.fullmatch(k)})
    elif selector == ":root":
      root_h.update({k: v for k, v in values.items() if hashed.fullmatch(k)})
    elif selector == "[color-version=v2_0] [dark],html[color-version=v2_0][dark]":
      sys_d.update({k: v for k, v in values.items() if k.startswith("--yt-sys-color-baseline--")})
    elif selector == "[color-version=v2_0] [light],html[color-version=v2_0]":
      sys_l.update({k: v for k, v in values.items() if k.startswith("--yt-sys-color-baseline--")})
  if not (dark_h and light_h and sys_d and sys_l):
    sys.exit("youtube-tokens: the stylesheet has a layout this script does not know (no token blocks)")
  pairs = {h: (dark_h.get(h, root_h.get(h)), light_h[h]) for h in light_h}
  return pairs, sys_d, sys_l


def align(pairs: dict, sys_d: dict, sys_l: dict) -> dict[str, str]:
  """The token each hashed variable copies. YouTube declares the copies in the order of the tokens, so walking both
  lists together tells apart tokens that share their colors (the page background and the inverse of the text, say)."""
  prefix = "--yt-sys-color-baseline--"
  tokens = [(name[len(prefix):], sys_d[name], sys_l.get(name)) for name in sys_d]
  found, at = {}, 0
  for name, colors in pairs.items():
    while at < len(tokens) and (tokens[at][1], tokens[at][2]) != colors:
      at += 1
    if at == len(tokens):
      return {}
    found[name] = tokens[at][0]
    at += 1
  return found


def build_block(css: str) -> str:
  pairs, sys_d, sys_l = read_tokens(css)
  prefix = "--yt-sys-color-baseline--"
  copies = align(pairs, sys_d, sys_l)
  if not copies:   # the order changed: take the first mapped token with the same colors
    by_colors: dict[tuple, list[str]] = {}
    for name in sys_d:
      by_colors.setdefault((sys_d[name], sys_l.get(name)), []).append(name[len(prefix):])
    copies = {h: next((s for s in by_colors.get(c, []) if s in MAP), "") for h, c in pairs.items()}
  # every variable to write: (name, short token name, dark color, light color)
  rows = [(prefix + short, short, sys_d.get(prefix + short), sys_l.get(prefix + short)) for short in MAP]
  rows += [(name, short, pairs[name][0], pairs[name][1]) for name, short in sorted(copies.items())]
  dark, light, kept = [], [], 0
  for name, short, dark_color, light_color in rows:
    a, b = declaration(short, dark_color, True), declaration(short, light_color, False)
    comment = f" /* {short} */" if name.startswith("--t") else ""
    if a:
      dark.append(f"  {name}: {a} !important;{comment}")
    if b:
      light.append(f"  {name}: {b} !important;{comment}")
    kept += not (a or b)
  lines = [BEGIN, f"/* {len(pairs)} hashed variables in YouTube's CSS; tools/youtube-tokens.py regenerates this */",
           "[dark] {", *dark, "}", ":root:not([dark]), [light] {", *light, "}",
           f"/* {kept} variables keep YouTube's colors (player overlays, add-on hues, ...) */", END]
  return "\n".join(lines)


def main() -> int:
  parser = argparse.ArgumentParser(description="Regenerate the token block of youtube.user.css from YouTube's CSS.")
  parser.add_argument("--css", help="read the stylesheet from this file")
  parser.add_argument("--file", default=str(USERCSS), help="the style to update")
  parser.add_argument("--print", action="store_true", help="print the block instead of writing it")
  args = parser.parse_args()
  css = Path(args.css).read_text() if args.css else fetch_css()
  block = build_block(css)
  if args.print:
    print(block)
    return 0
  target = Path(args.file)
  text = target.read_text()
  if BEGIN not in text or END not in text:
    sys.exit(f"youtube-tokens: {target} has no {BEGIN} ... {END} markers")
  head, rest = text.split(BEGIN, 1)
  tail = rest.split(END, 1)[1]
  target.write_text(head + block + tail)
  print(f"updated {target}")
  return 0


if __name__ == "__main__":
  sys.exit(main())
