.pragma library

// Every option of the widget with its default. The config file only has to hold what differs from this; the settings
// dialog writes all of it. Colors are "theme:<name>" (accent, highlight, text, dimmed, background, positive,
// negative, neutral, link) so the widget follows the Plasma color scheme, or any "#rrggbb" / "#aarrggbb".
//
// A desktop with programs shows its pill instead of the circle.
// circle fill: solid, outline, dot, ring, half, level (filled from the bottom by the number of windows), gradient, none
var defaults = {
  layout: {
    orientation: "auto",      // auto follows the panel, or horizontal / vertical
    spacing: 10,              // gap between desktops
    margin: 4                 // space at both ends of the widget
  },
  circles: {
    size: 12,
    borderWidth: 2,
    label: "none",            // none, number or name, drawn inside the circle
    labelSize: 8,
    labelColor: "theme:background",
    levelMax: 4,              // windows that fill a "level" circle
    animation: 140,           // ms
    active: { fill: "solid", color: "theme:accent", border: "theme:accent", opacity: 1, scale: 1 },
    occupied: { fill: "dot", color: "theme:text", border: "theme:text", opacity: 0.85, scale: 1 },
    empty: { fill: "outline", color: "theme:text", border: "theme:text", opacity: 0.35, scale: 1 },
    urgent: { fill: "solid", color: "theme:negative", border: "theme:negative", opacity: 1, scale: 1 },
    hover: { opacity: 1, scale: 1 }
  },
  programs: {
    show: true,
    showOn: "all",            // all desktops with windows, or active (the current desktop only)
    onePerApp: true,          // one icon per program, however many windows it has
    maxIcons: 5,
    overflow: "count",        // count shows +N for the rest, none hides them
    overflowColor: "theme:text",  // the color of that +N
    iconSize: 16,
    iconSpacing: 4,
    iconOpacity: 0.85,
    activeIconOpacity: 1,
    highlightFocused: true,   // a small bar under the icon of the focused window
    pill: {
      paddingX: 6,
      paddingY: 3,
      radius: -1,             // -1 for a full pill
      color: "theme:text",
      opacity: 0.1,
      activeColor: "theme:accent",
      activeOpacity: 0.2,
      border: "theme:text",
      borderOpacity: 0.15,
      activeBorder: "theme:accent",
      activeBorderOpacity: 0.3,
      borderWidth: 1
    }
  },
  behavior: {
    clickSwitches: true,
    wheel: true,              // scroll over the widget to change desktop
    wrap: false,              // the wheel goes from the last desktop to the first
    iconClickFocuses: true,   // a click on a program icon focuses that program
    currentActivityOnly: true,
    currentScreenOnly: false,
    tooltip: true
  }
}

function clone(value) {
  return JSON.parse(JSON.stringify(value))
}

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value)
}

// A copy of base with every value of extra on top, key by key. Keys base does not know are kept.
function merge(base, extra) {
  var out = clone(base)
  if (!isObject(extra)) {
    return out
  }
  for (var key in extra) {
    if (isObject(extra[key]) && isObject(out[key])) {
      out[key] = merge(out[key], extra[key])
    } else {
      out[key] = extra[key]
    }
  }
  return out
}

// The effective config: the defaults with what the file holds on top.
function effective(user) {
  return merge(defaults, user)
}

var hexColor = /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/

function isHex(spec) {
  return typeof spec === "string" && hexColor.test(spec)
}
