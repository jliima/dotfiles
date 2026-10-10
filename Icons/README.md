# Icons

Plasma icon themes in the colors of a Themer theme, recolored with [gowall](https://github.com/Achno/gowall).

| Folder | What | Themes |
| --- | --- | --- |
| `monochrome/` | Two tones: the grounds (bg, surface, line) and the accent (blue in Pare, orange in Aphelion) | `Pare-Monochrome`, `Aphelion-Monochrome`, each with a `-Light` twin |
| `colorful/` | Every color of the theme | `Pare-Colorful`, `Aphelion-Colorful`, each with a `-Light` twin |

Each folder inside is a complete XDG icon theme (`index.theme`, `<context>/<size>/<name>.png`) that inherits Breeze
Chameleon Dark, Breeze and hicolor, so it only replaces the icons listed in `icons.toml`. `.local/share/icons/` links
them into place (stowed), and a Themer theme selects one:

```toml
[icons]
theme = "Pare-Colorful"            # the dark variant
theme-light = "Pare-Colorful-Light"
```

`themer apply` writes `[Icons] Theme=` into kdeglobals and tells running apps. To switch Pare to the two-tone set, change
the two names in `.config/themer/themes/pare/theme.toml`, or for this machine only add
`[overrides.icons] theme = "Pare-Monochrome"` (and `theme-light`) to `~/.config/themer/settings.toml`. Plasma re-reads
tray icons when plasmashell restarts (`systemctl --user restart plasma-plasmashell.service`).

## Building

```sh
icon-sets build -t pare -v both                  # both sets, dark and light
icon-sets build --sets colorful --only 'audio-*' # a part of one set
icon-sets list                                   # what icons.toml resolves to
icon-sets preview Icons/colorful/Pare-Colorful audio-volume-high firefox -o sheet.png
```

`icons.toml` lists the icons: groups of name globs for the right-hand panel (system tray applets and their states), and
`[[app]]` entries for application icons: Firefox, Dolphin, Kate, Konsole, Obsidian, Calc, Okular, IntelliJ, KeePassXC,
VS Code, Chromium, Slack, Spotify, Wireshark and the other tray items. Slack's own desktop entry names its icon by file,
so `.local/share/applications/slack.desktop` is a copy that names it, which a theme can replace.

The palette of each set is a list of Themer token names, so another theme gets its own icons with
`icon-sets build -t noire`. Needs gowall, inkscape, themer and Pillow.

How an icon is made: the source icon (SVG rendered by inkscape at each size, or PNG scaled) goes through gowall's
nearest-color mapping to the palette, so a result only has colors of the theme, and the original alpha is put back.
Breeze glyphs are painted first: their color scheme classes get a color per set (the blue in the two-tone set, a hue per
group in the colorful one: green for audio, cyan for network, and so on).
