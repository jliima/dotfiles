import QtQuick
import org.kde.kirigami as Kirigami
import "../code/defaults.js" as Defaults

// Turns a color of the config ("theme:highlight" or "#rrggbb") into a color, following the Plasma color scheme for the
// theme ones. Bindings that call resolve() update when the scheme changes.
Item {
  visible: false

  function resolve(spec, opacity) {
    var c
    switch (spec) {
    case "theme:accent": c = Kirigami.Theme.focusColor; break
    case "theme:highlight": c = Kirigami.Theme.highlightColor; break
    case "theme:text": c = Kirigami.Theme.textColor; break
    case "theme:dimmed": c = Kirigami.Theme.disabledTextColor; break
    case "theme:background": c = Kirigami.Theme.backgroundColor; break
    case "theme:positive": c = Kirigami.Theme.positiveTextColor; break
    case "theme:negative": c = Kirigami.Theme.negativeTextColor; break
    case "theme:neutral": c = Kirigami.Theme.neutralTextColor; break
    case "theme:link": c = Kirigami.Theme.linkColor; break
    default:
      c = Defaults.isHex(spec) ? Qt.color(spec) : Kirigami.Theme.textColor
    }
    if (opacity === undefined || opacity >= 1) {
      return c
    }
    return Qt.rgba(c.r, c.g, c.b, c.a * Math.max(0, opacity))
  }
}
