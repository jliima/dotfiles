#!/usr/bin/env python3
"""Builds Plasma icon themes in the colors of a Themer theme with gowall.

Reads Icons/icons.toml (which icons, from where, which palette) and writes two XDG icon themes per Themer theme and
variant into the Icons folder of the dotfiles:

    monochrome/<Theme>-Monochrome[-Light]   two tones: the grounds and the blue
    colorful/<Theme>-Colorful[-Light]       every color of the theme

Each icon is rendered at every size it is wanted at (inkscape for SVG, Pillow for PNG), gowall maps every color to
the palette (nearest color, so only theme colors are left), and the alpha channel of the original is put back. The
result inherits the original icon themes, so it only replaces what is listed.

Usage:
    icon_sets.py build -t pare -v dark          one theme variant, both sets
    icon_sets.py build -t pare --sets colorful --only 'audio-*,firefox'
    icon_sets.py list                           what the manifest resolves to
    icon_sets.py preview THEMEDIR NAME...       a contact sheet of built icons

Dependencies: gowall, inkscape, themer (external); Pillow (python3-pil)
"""

from __future__ import annotations

import argparse
import concurrent.futures
import dataclasses
import fnmatch
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib

from PIL import Image

# The helpers package sits next to the script folders, which are not on the import path.
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2]))
from helpers import log  # pylint: disable=wrong-import-position

SCRIPT_DIR = pathlib.Path(__file__).parent.resolve()
DOTFILES = SCRIPT_DIR.parents[2]
DEFAULT_ICONS_DIR = DOTFILES / "Icons"
ICON_ROOTS = [
    pathlib.Path.home() / ".local/share/icons",
    pathlib.Path.home() / ".icons",
    pathlib.Path("/usr/local/share/icons"),
    pathlib.Path("/usr/share/icons"),
    pathlib.Path.home() / ".local/share/flatpak/exports/share/icons",
    pathlib.Path("/var/lib/flatpak/exports/share/icons"),
]
PIXMAP_DIR = pathlib.Path("/usr/share/pixmaps")
SETS = ("monochrome", "colorful")
# Where an icon is written when several contexts of the source theme have it.
CONTEXTS = {
    "status": "Status",
    "actions": "Actions",
    "devices": "Devices",
    "apps": "Applications",
    "places": "Places",
    "mimetypes": "MimeTypes",
    "categories": "Categories",
    "applets": "Applets",
    "emblems": "Emblems",
    "preferences": "Applications",
    "animations": "Animations",
    "emotes": "Emotes",
}
CONTEXT_ORDER = [
    "status",
    "actions",
    "devices",
    "apps",
    "preferences",
    "applets",
    "places",
    "mimetypes",
    "categories",
    "emblems",
    "animations",
    "emotes",
]
GLYPH_MAX_SIZE = 24
INKSCAPE_PROCESSES = 4
INKSCAPE_CHUNK = 150


@dataclasses.dataclass(frozen=True)
class Entry:
    """One file of a source icon theme."""

    theme_rank: int
    theme: str
    context: str
    size: int  # 0 for scalable
    ext: str
    path: pathlib.Path


SIZE_RE = re.compile(r"^(\d+)(?:x\d+)?$")


class IconIndex:
    """Every svg and png of the source themes, by icon name."""

    def __init__(self, themes: list[str]) -> None:
        """Scans the source themes, earlier themes ranking higher."""
        self.by_name: dict[str, list[Entry]] = {}
        self.themes = themes
        for rank, theme in enumerate(themes):
            roots = [r / theme for r in ICON_ROOTS if (r / theme).is_dir()]
            if theme == "pixmaps":
                roots = [PIXMAP_DIR] if PIXMAP_DIR.is_dir() else []
            if not roots:
                log.warn(f"source theme {theme!r} not found")
            for root in roots:
                self._scan(root, rank, theme)

    def _scan(self, root: pathlib.Path, rank: int, theme: str) -> None:
        """Adds every svg and png below root to the index."""
        for dirpath, _dirs, files in os.walk(root, followlinks=True):
            rel = pathlib.Path(dirpath).relative_to(root).parts
            if any("@" in part for part in rel):
                continue
            size, context = 0, ""
            for part in rel:
                match = SIZE_RE.match(part)
                if match:
                    size = int(match.group(1))
                elif part in CONTEXTS:
                    context = part
            for filename in files:
                stem, ext = os.path.splitext(filename)
                if ext not in (".svg", ".png"):
                    continue
                self.by_name.setdefault(stem, []).append(
                    Entry(rank, theme, context or "apps", size, ext[1:], pathlib.Path(dirpath) / filename)
                )

    def names(self) -> list[str]:
        """Returns every icon name in the index, sorted."""
        return sorted(self.by_name)

    def context_of(self, name: str) -> str:
        """Returns the icon theme context (Actions, Status, ...) the icon is filed under."""
        entries = self.by_name.get(name, [])
        contexts = {e.context for e in entries}
        for context in CONTEXT_ORDER:
            if context in contexts:
                return context
        return "apps"

    def pick(
        self,
        name: str,
        size: int,
        extra: list[pathlib.Path] | None = None,
        glyph: bool = False,
        themes: list[str] | None = None,
    ) -> tuple[pathlib.Path, str] | None:
        """Returns the best source file to build `name` at `size` as (path, 'svg'|'png').

        The first source theme that has the icon wins (`themes` are tried before the rest); inside
        it an SVG (exact size, scalable, nearest size) before a PNG (exact, larger, smaller). A glyph only comes from
        small sizes or symbolic folders: larger ones are full color app style icons.
        """
        entries = list(self.by_name.get(name, []))
        if themes:
            order = {theme: rank for rank, theme in enumerate(themes + [t for t in self.themes if t not in themes])}
            entries = [
                Entry(order[e.theme], e.theme, e.context, e.size, e.ext, e.path) for e in entries if e.theme in order
            ]
        if glyph:
            entries = [
                e for e in entries if 0 < e.size <= GLYPH_MAX_SIZE or (e.size == 0 and "symbolic" in e.path.parts)
            ]
        for path in extra or []:
            entries.insert(0, Entry(-1, "", "apps", 0, path.suffix.lstrip("."), path))
        if not entries:
            return None
        best_rank = min(e.theme_rank for e in entries)
        pool = [e for e in entries if e.theme_rank == best_rank]
        svgs = [e for e in pool if e.ext == "svg"]
        pngs = [e for e in pool if e.ext == "png"]
        if svgs:
            exact = [e for e in svgs if e.size == size]
            scalable = [e for e in svgs if e.size == 0]
            if exact:
                return exact[0].path, "svg"
            if scalable:
                return scalable[0].path, "svg"
            larger = sorted((e for e in svgs if e.size > size), key=lambda e: e.size)
            return (larger[0] if larger else max(svgs, key=lambda e: e.size)).path, "svg"
        exact = [e for e in pngs if e.size == size]
        if exact:
            return exact[0].path, "png"
        larger = sorted((e for e in pngs if e.size > size), key=lambda e: e.size)
        if larger:
            return larger[0].path, "png"
        smaller = max(pngs, key=lambda e: e.size, default=None)
        if smaller and (smaller.size == 0 or smaller.size * 2 >= size):
            return smaller.path, "png"
        return None


def themer_tokens(theme: str, variant: str) -> dict[str, str]:
    """Every color token of a Themer theme variant, from `themer tokens`."""
    if not shutil.which("themer"):
        log.die("themer is not on PATH")
    result = subprocess.run(
        ["themer", "tokens", "-t", theme, "-v", variant], capture_output=True, text=True, check=False
    )
    if result.returncode != 0:
        log.die(f"themer tokens failed: {result.stderr.strip()}")
    tokens = {}
    for line in result.stdout.splitlines():
        match = re.match(r"^(\S+)\s+(#[0-9a-fA-F]{6})\s*$", line)
        if match:
            tokens[match.group(1)] = match.group(2).lower()
    return tokens


def theme_title(theme: str) -> str:
    """Returns the theme name with a capital first letter."""
    return theme[:1].upper() + theme[1:]


HUES = ("red", "orange", "yellow", "green", "cyan", "blue", "violet", "magenta")


def accent_hue(tokens: dict[str, str]) -> str:
    """The hue the theme's accent is, so a manifest can say {accent} and get blue for Pare and orange for Aphelion."""
    for hue in HUES:
        if tokens.get(hue) == tokens.get("accent"):
            return hue
    return "blue"


def expand_tokens(patterns: list[str], tokens: dict[str, str]) -> list[str]:
    """Hex colors of the tokens a palette lists, in order and without duplicates."""
    colors: list[str] = []
    hue = accent_hue(tokens)
    for raw_pattern in patterns:
        pattern = raw_pattern.replace("{accent}", hue)
        for name, value in tokens.items():
            if fnmatch.fnmatchcase(name, pattern) and value not in colors:
                colors.append(value)
    return colors


def glyph_color(mapping: dict[str, str], cls: str, tokens: dict[str, str], hue: str) -> str:
    """The color a glyph class gets: its token with {hue} (the group's) and {accent} (the theme's) filled in."""
    token = mapping[cls].replace("{hue}", hue).replace("{accent}", accent_hue(tokens))
    if token not in tokens:
        log.die(f"glyph color {token!r} is not a token of the theme")
    return tokens[token]


def glyph_css(mapping: dict[str, str], tokens: dict[str, str], hue: str) -> str:
    """Returns the CSS that gives every color scheme class its glyph color."""
    return " ".join(f".ColorScheme-{cls} {{ color: {glyph_color(mapping, cls, tokens, hue)}; }}" for cls in mapping)


STYLE_RE = re.compile(r"(<style\b[^>]*>)(.*?)(</style>)", re.S)
INLINE_COLOR_RE = re.compile(r"(?<![-\w])color\s*:\s*#[0-9a-fA-F]{3,8}\s*;?")
HEX_RE = re.compile(r"#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{3})(?![0-9a-zA-Z])")


def is_neutral(hex_color: str) -> bool:
    """Returns whether the hex color is a gray."""
    digits = hex_color.lstrip("#")
    if len(digits) == 3:
        digits = "".join(c * 2 for c in digits)
    channels = [int(digits[i : i + 2], 16) for i in (0, 2, 4)]
    return max(channels) - min(channels) <= 24


def recolor_glyph(svg_text: str, css: str, text_color: str) -> str:
    """Paints a Breeze glyph.

    Its color scheme classes get the glyph colors; gray colors written into the shapes (some glyphs hard-code #232629 or
    #fcfcfc instead of using a class) become the text color; inline color: properties go, because they would win over
    the classes.
    """
    svg_text = INLINE_COLOR_RE.sub("", svg_text)
    svg_text = STYLE_RE.sub(lambda m: f"{m.group(1)}{m.group(3)}", svg_text)  # the old class colors
    svg_text = HEX_RE.sub(lambda m: text_color if is_neutral(m.group(0)) else m.group(0), svg_text)
    if STYLE_RE.search(svg_text):
        return STYLE_RE.sub(lambda m: f"{m.group(1)}{css}{m.group(3)}", svg_text, count=1)
    # No style element: set the class colors and the default (currentColor) on a new one
    return re.sub(
        r"(<svg\b[^>]*>)",
        lambda m: f"{m.group(1)}<style>svg {{ color: {text_color}; }} {css}</style>",
        svg_text,
        count=1,
    )


def inkscape_render(jobs: list[tuple[pathlib.Path, pathlib.Path, int]]) -> None:
    """Renders (svg, png, size) jobs with a few inkscape shell processes.

    Parallel processes sometimes lose a chunk (they share one profile), so what is missing afterwards is rendered again,
    with fewer processes.
    """
    if not jobs:
        return
    if not shutil.which("inkscape"):
        log.die("inkscape is not on PATH")

    def run(chunk: list[tuple[pathlib.Path, pathlib.Path, int]]) -> None:
        """Renders one chunk of jobs in a single inkscape shell."""
        script = "".join(
            f"file-open:{svg}; export-type:png; export-width:{size}; export-height:{size}; "
            f"export-background-opacity:0; export-filename:{png}; export-do; file-close\n"
            for svg, png, size in chunk
        )
        subprocess.run(["inkscape", "--shell"], input=script, text=True, capture_output=True, check=False)

    pending = jobs
    for processes in (INKSCAPE_PROCESSES, 2, 1, 1):
        chunks = [pending[i : i + INKSCAPE_CHUNK] for i in range(0, len(pending), INKSCAPE_CHUNK)]
        with concurrent.futures.ThreadPoolExecutor(processes) as pool:
            list(pool.map(run, chunks))
        pending = [job for job in pending if not job[1].exists()]
        if not pending:
            return
    for svg, _png, size in pending:
        log.warn(f"inkscape could not render {svg} at {size}")


def prepare_png(src: pathlib.Path, dst: pathlib.Path, size: int) -> None:
    """A PNG source scaled to size x size, centered and padded if it is not square."""
    img = Image.open(src).convert("RGBA")
    if img.size != (size, size):
        scale = size / max(img.size)
        new = (max(1, round(img.width * scale)), max(1, round(img.height * scale)))
        img = img.resize(new, Image.LANCZOS)
        canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        canvas.paste(img, ((size - new[0]) // 2, (size - new[1]) // 2))
        img = canvas
    img.save(dst)


@dataclasses.dataclass
class Item:
    """One icon of one set at its sizes."""

    name: str
    context: str
    sizes: list[int]
    glyph: bool
    hue: str
    group: str
    sources: list[pathlib.Path] = dataclasses.field(default_factory=list)
    aliases: list[str] = dataclasses.field(default_factory=list)
    source_name: str = ""  # the icon name to look up when it is not the name
    themes: list[str] = dataclasses.field(
        default_factory=list
    )  # source themes in order of preference, empty for the default
    any_size: bool = False  # a glyph may come from any folder, not only small sizes and symbolic ones

    def pick(self, index: IconIndex, size: int) -> tuple[pathlib.Path, str] | None:
        """Returns the source file for this item at the size, see IconIndex.pick."""
        return index.pick(
            self.source_name or self.name, size, self.sources, self.glyph and not self.any_size, self.themes
        )


def load_manifest(path: pathlib.Path) -> dict:
    """Returns the parsed icons.toml, exiting when it does not exist."""
    if not path.exists():
        log.die(f"manifest {path} not found")
    with path.open("rb") as handle:
        return tomllib.load(handle)


def plan_items(manifest: dict, index: IconIndex, only: list[str], icons_dir: pathlib.Path) -> list[Item]:
    """The icons the manifest asks for, with globs resolved against the source themes."""
    items: dict[str, Item] = {}
    for group in manifest.get("group", []):
        sizes = group.get("sizes", [16, 22, 24, 32])
        for pattern in group.get("names", []):
            matched = (
                fnmatch.filter(index.names(), pattern)
                if any(c in pattern for c in "*?[")
                else ([pattern] if pattern in index.by_name else [])
            )
            for name in matched:
                if name in items:
                    continue
                hue = group.get("hue", "blue")
                for glob, other in group.get("hue-by-name", {}).items():
                    if fnmatch.fnmatchcase(name, glob):
                        hue = other
                items[name] = Item(
                    name,
                    group.get("context") or index.context_of(name),
                    sizes,
                    group.get("glyph", False),
                    hue,
                    group.get("id", "group"),
                    any_size=group.get("any-size", False),
                )
    for app in manifest.get("app", []):
        name = app["name"]
        sources = [pathlib.Path(os.path.expanduser(s)) for s in app.get("files", [])]
        sources = [s if s.is_absolute() else icons_dir / s for s in sources]
        items[name] = Item(
            name,
            app.get("context", "apps"),
            app.get("sizes", [16, 22, 24, 32, 48, 64, 128, 256]),
            app.get("glyph", False),
            app.get("hue", "blue"),
            "apps",
            sources,
            app.get("aliases", []),
            app.get("source", name),
            app.get("themes", []),
        )
    chosen = list(items.values())
    if only:
        chosen = [i for i in chosen if any(fnmatch.fnmatchcase(i.name, p) for p in only)]
    return chosen


def gowall_map(
    indir: pathlib.Path, outdir: pathlib.Path, palette: list[str], workdir: pathlib.Path, backend: str
) -> None:
    """Maps every image of indir to the palette with gowall.

    It runs with its own HOME, so the user's gowall config stays out. The palette is a theme of that config: gowall
    loads a theme file once per image, in parallel, and crashes on a directory with many images ("concurrent map read
    and map write").
    """
    home = workdir / "home"
    (home / ".config/gowall").mkdir(parents=True, exist_ok=True)
    colors = "".join(f'      - "{color}"\n' for color in palette)
    (home / ".config/gowall/config.yml").write_text(
        f"ColorCorrectionBackend: {backend}\nEnableImagePreviewing: false\n"
        f"themes:\n  - name: palette\n    colors:\n{colors}"
    )
    outdir.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, HOME=str(home))
    result = subprocess.run(
        ["gowall", "convert", "--dir", str(indir), "-t", "palette", "--output", str(outdir), "--yes"],
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        log.die(f"gowall failed on {indir}: {result.stdout[-300:]} {result.stderr[-600:]}")


def build_set(
    set_name: str,
    theme: str,
    variant: str,
    items: list[Item],
    index: IconIndex,
    manifest: dict,
    tokens: dict[str, str],
    out_root: pathlib.Path,
    workdir: pathlib.Path,
    backend: str,
    clean: bool,
) -> pathlib.Path:
    """Builds one icon theme (monochrome or colorful) for a Themer theme and variant."""
    light = variant == "light"
    theme_dir_name = f"{theme_title(theme)}-{set_name.capitalize()}" + ("-Light" if light else "")
    theme_dir = out_root / set_name / theme_dir_name
    palette = expand_tokens(manifest["palette"][set_name]["tokens"], tokens)
    glyph_map = manifest["glyph"][set_name]
    work = workdir / f"{theme_dir_name}"
    shutil.rmtree(work, ignore_errors=True)

    # 1. render every icon at every size into work/src/<size>/<name>.png
    svg_jobs: list[tuple[pathlib.Path, pathlib.Path, int]] = []
    built: list[tuple[Item, int, pathlib.Path]] = []
    skipped = 0
    for item in items:
        for size in item.sizes:
            picked = item.pick(index, size)
            if not picked:
                skipped += 1
                continue
            path, kind = picked
            dst = work / "src" / str(size) / f"{item.name}.png"
            dst.parent.mkdir(parents=True, exist_ok=True)
            if kind == "svg":
                svg = path
                if item.glyph:
                    css = glyph_css(glyph_map, tokens, item.hue)
                    text_color = glyph_color(glyph_map, "Text", tokens, item.hue)
                    svg = work / "svg" / str(size) / f"{item.name}.svg"
                    svg.parent.mkdir(parents=True, exist_ok=True)
                    svg.write_text(recolor_glyph(path.read_text(errors="replace"), css, text_color))
                svg_jobs.append((svg, dst, size))
            else:
                prepare_png(path, dst, size)
            built.append((item, size, dst))
    inkscape_render(svg_jobs)
    built = [(i, s, p) for i, s, p in built if p.exists()]
    log.info(f"{theme_dir_name}: {len(built)} icon images rendered ({skipped} sizes had no source)")

    # 2. opaque copies (straight colors, so edge pixels map like the pixels next to them), gowall, alpha back
    sizes = sorted({s for _i, s, _p in built})
    alphas: dict[pathlib.Path, Image.Image] = {}
    for _item, size, src in built:
        img = Image.open(src).convert("RGBA")
        alphas[src] = img.getchannel("A")
        opaque = work / "opaque" / str(size) / src.name
        opaque.parent.mkdir(parents=True, exist_ok=True)
        Image.merge("RGB", img.split()[:3]).save(opaque)
    for size in sizes:
        gowall_map(work / "opaque" / str(size), work / "mapped" / str(size), palette, work, backend)

    # 3. write the theme
    if clean:
        shutil.rmtree(theme_dir, ignore_errors=True)
    directories: set[tuple[str, int]] = set()
    for item, size, src in built:
        mapped = work / "mapped" / str(size) / src.name
        if not mapped.exists():
            log.warn(f"gowall made nothing for {item.name} at {size}")
            continue
        img = Image.open(mapped).convert("RGB")
        img.putalpha(alphas[src])
        for name in [item.name] + item.aliases:
            dst = theme_dir / item.context / str(size) / f"{name}.png"
            dst.parent.mkdir(parents=True, exist_ok=True)
            img.save(dst, optimize=True)
        directories.add((item.context, size))
    write_index(theme_dir, theme, set_name, light, sorted(directories, key=lambda d: (d[0], d[1])), manifest)
    count = sum(1 for _ in theme_dir.rglob("*.png"))
    log.success(
        f"{theme_dir.relative_to(out_root.parent) if out_root.parent in theme_dir.parents else theme_dir}: "
        f"{count} files, {len(palette)} palette colors"
    )
    return theme_dir


def write_index(
    theme_dir: pathlib.Path, theme: str, set_name: str, light: bool, directories: list[tuple[str, int]], manifest: dict
) -> None:
    """Writes the theme's index.theme file."""
    title = f"{theme_title(theme)} {set_name.capitalize()}" + (" Light" if light else "")
    lines = [
        "[Icon Theme]",
        f"Name={title}",
        f"Comment={title} icons, recolored with gowall to the colors of the {theme_title(theme)} Themer theme",
        f"Inherits={','.join(t for t in manifest['source-themes'] if t != 'pixmaps')}",
        "Directories=" + ",".join(f"{ctx}/{size}" for ctx, size in directories),
        "",
    ]
    for ctx, size in directories:
        lines += [f"[{ctx}/{size}]", f"Size={size}", f"Context={CONTEXTS.get(ctx, 'Applications')}", "Type=Fixed", ""]
    (theme_dir / "index.theme").write_text("\n".join(lines))


def cmd_build(args: argparse.Namespace) -> None:
    """Runs the build command."""
    icons_dir = pathlib.Path(args.icons).expanduser().resolve()
    manifest = load_manifest(icons_dir / "icons.toml")
    index = IconIndex(manifest["source-themes"])
    only = [p for p in args.only.split(",") if p] if args.only else []
    items = plan_items(manifest, index, only, icons_dir)
    if not items:
        log.die("nothing to build")
    log.info(f"{len(items)} icons")
    sets = [s for s in args.sets.split(",") if s]
    for s in sets:
        if s not in SETS:
            log.die(f"unknown set {s!r} (use {', '.join(SETS)})")
    variants = ["dark", "light"] if args.variant == "both" else [args.variant]
    workdir = pathlib.Path(args.work).expanduser() if args.work else pathlib.Path(tempfile.mkdtemp(prefix="icon-sets-"))
    workdir.mkdir(parents=True, exist_ok=True)
    try:
        for variant in variants:
            tokens = themer_tokens(args.theme, variant)
            for set_name in sets:
                log.header(f"{args.theme} {variant} {set_name}")
                build_set(
                    set_name,
                    args.theme,
                    variant,
                    items,
                    index,
                    manifest,
                    tokens,
                    icons_dir,
                    workdir,
                    args.backend,
                    clean=not only,
                )
    finally:
        if not args.keep_work:
            shutil.rmtree(workdir, ignore_errors=True)


def cmd_list(args: argparse.Namespace) -> None:
    """Runs the list command."""
    icons_dir = pathlib.Path(args.icons).expanduser().resolve()
    manifest = load_manifest(icons_dir / "icons.toml")
    index = IconIndex(manifest["source-themes"])
    items = plan_items(manifest, index, [], icons_dir)
    by_group: dict[str, list[Item]] = {}
    for item in items:
        by_group.setdefault(item.group, []).append(item)
    for group, members in by_group.items():
        log.header(f"{group}: {len(members)} icons")
        for item in members:
            missing = [s for s in item.sizes if not item.pick(index, s)]
            note = f"  (no source at {missing})" if missing else ""
            print(f"  {item.name}{note}")
    for group in manifest.get("group", []):
        for pattern in group.get("names", []):
            if not any(fnmatch.fnmatchcase(i.name, pattern) for i in items):
                log.warn(f"{group.get('id')}: {pattern!r} matches no icon")


def cmd_preview(args: argparse.Namespace) -> None:
    """A contact sheet: each named icon at each size of a built theme, on the theme's ground."""
    theme_dir = pathlib.Path(args.themedir).expanduser().resolve()
    ground = tuple(int(args.ground.lstrip("#")[i : i + 2], 16) for i in (0, 2, 4))
    rows = []
    for name in args.names:
        found = sorted(theme_dir.glob(f"*/*/{name}.png"), key=lambda p: int(p.parent.name))
        if not found:
            log.warn(f"{name}: not in {theme_dir.name}")
            continue
        rows.append([Image.open(p).convert("RGBA") for p in found])
    if not rows:
        log.die("nothing to show")
    pad = 10
    width = max(sum(i.width + pad for i in row) for row in rows) + pad
    height = sum(max(i.height for i in row) + pad for row in rows) + pad
    sheet = Image.new("RGBA", (width, height), ground + (255,))
    y = pad
    for row in rows:
        x = pad
        for img in row:
            sheet.alpha_composite(img, (x, y))
            x += img.width + pad
        y += max(i.height for i in row) + pad
    out = pathlib.Path(args.output)
    sheet.convert("RGB").save(out)
    log.success(f"{out} ({len(rows)} icons)")


def main() -> None:
    """Parses the command line and runs the chosen command."""
    parser = argparse.ArgumentParser(description="Build Plasma icon themes in the colors of a Themer theme.")
    parser.add_argument("--icons", default=str(DEFAULT_ICONS_DIR), help="the Icons folder (default: the dotfiles one)")
    sub = parser.add_subparsers(dest="command", required=True)

    build = sub.add_parser("build", help="build the icon themes")
    build.add_argument("-t", "--theme", default="pare", help="Themer theme id (default: pare)")
    build.add_argument("-v", "--variant", choices=["dark", "light", "both"], default="dark")
    build.add_argument("--sets", default=",".join(SETS), help="monochrome, colorful or both (default)")
    build.add_argument("--only", default="", help="comma separated name globs; only these icons are rebuilt")
    build.add_argument(
        "--backend",
        choices=["nn", "clut"],
        default="nn",
        help="nn maps to the nearest palette color, clut blends smoothly between them",
    )
    build.add_argument("--work", default="", help="work folder (default: a temporary one)")
    build.add_argument("--keep-work", action="store_true")
    build.set_defaults(func=cmd_build)

    listing = sub.add_parser("list", help="show what the manifest resolves to")
    listing.set_defaults(func=cmd_list)

    preview = sub.add_parser("preview", help="a contact sheet of icons of a built theme")
    preview.add_argument("themedir")
    preview.add_argument("names", nargs="+")
    preview.add_argument("-o", "--output", default="icon-preview.png")
    preview.add_argument("--ground", default="#070c12")
    preview.set_defaults(func=cmd_preview)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
