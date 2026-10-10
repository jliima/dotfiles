# Desktop Dots

A Plasma 6 widget that shows every virtual desktop as a circle, and optionally the programs open on it as icons in a
pill. It replaces the Pager and needs nothing else (no theme tool, no extra packages).

Add it to a panel like any widget (right-click the panel, Add Widgets, "Desktop Dots") and open its settings for the
three pages: Circles, Programs and Behavior.

## What you can change

- **Circles**: size, border width, gaps between desktops, text inside (number or name) and how each state looks:
  the current desktop, a desktop with windows, an empty desktop, one with a window that wants attention, and under the
  mouse. A circle can be solid, an outline, a ring with a dot, a thick ring, half filled, filled from the bottom by the
  number of windows, a gradient, or invisible; each state has its own color, border color, opacity and size.
- **Programs**: an icon for every program that has a window on the desktop, one per program however many windows it
  has (or one per window), in a pill. Choose the icon size, the gap between icons, how many show (the rest as +N),
  where the pill sits (after, before, below, above, or around the circle), its padding, corner radius, colors and
  border, and a bar under the focused program. Pills can show on every desktop or only on the current one.
- **Behavior**: click a desktop to switch to it, click an icon to focus that program, scroll over the widget to change
  desktop (with or without wrapping), tooltips, and whether only the current activity's and this screen's windows count.

## The settings file

The look is saved in `~/.config/desktopdots/config.json` (the path is a setting, relative to `~/.config`; widgets with
the same path share one look). The file is plain JSON, and the widget follows it live: edit it by hand, or let a script
or a color scheme tool write it, and every panel showing the widget updates at once. Anything left out of the file
keeps its default, so a short file is fine:

```json
{
  "circles": { "size": 14, "active": { "fill": "gradient", "color": "#5faff1" } },
  "layout": { "pillPosition": "inside" },
  "programs": { "iconSize": 18, "pill": { "radius": 8 } }
}
```

All options and their defaults are in `contents/code/defaults.js`. Colors are `"#rrggbb"` / `"#aarrggbb"`, or
`"theme:accent"`, `highlight`, `text`, `dimmed`, `background`, `positive`, `negative`, `neutral`, `link` to follow the
Plasma color scheme (the default).

Program icons come from the active icon theme, so a themed icon set shows up in the pills too.

## Install

Copy the folder to `~/.local/share/plasma/plasmoids/com.jliima.desktopdots` (a real folder or a link to the folder, not
links to single files, which Plasma refuses), or `kpackagetool6 -t Plasma/Applet --install .` from inside it.
