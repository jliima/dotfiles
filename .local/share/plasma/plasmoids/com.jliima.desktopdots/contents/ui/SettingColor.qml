import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kquickcontrols as KQuickControls
import "../code/defaults.js" as Defaults

// A color of the config: one of the Plasma color scheme's colors, or a color of your own. opacityPath, when set, adds
// an opacity in percent.
RowLayout {
  id: field

  required property var page
  required property string path
  property string opacityPath: ""

  readonly property string value: String(page.get(path))
  readonly property bool custom: !value.startsWith("theme:")

  QQC2.ComboBox {
    id: choice
    textRole: "text"
    valueRole: "value"
    model: [
      { text: "Accent", value: "theme:accent" },
      { text: "Selection", value: "theme:highlight" },
      { text: "Text", value: "theme:text" },
      { text: "Dimmed text", value: "theme:dimmed" },
      { text: "Background", value: "theme:background" },
      { text: "Positive", value: "theme:positive" },
      { text: "Negative", value: "theme:negative" },
      { text: "Neutral", value: "theme:neutral" },
      { text: "Link", value: "theme:link" },
      { text: "Custom", value: "custom" }
    ]
    // Set from code: a binding is lost when the model is assigned after it
    function sync() {
      currentIndex = field.custom ? indexOfValue("custom") : indexOfValue(field.value)
    }
    Component.onCompleted: sync()
    Connections {
      target: field
      function onValueChanged() { choice.sync() }
    }
    onActivated: {
      if (currentValue === "custom") {
        field.page.set(field.path, Defaults.isHex(colorButton.lastCustom) ? colorButton.lastCustom : "#5faff1")
      } else {
        field.page.set(field.path, currentValue)
      }
    }
  }

  KQuickControls.ColorButton {
    id: colorButton
    visible: field.custom
    showAlphaChannel: true
    property string lastCustom: ""
    color: Defaults.isHex(field.value) ? field.value : "#ffffff"
    onAccepted: (picked) => {
      lastCustom = picked.toString()
      field.page.set(field.path, picked.toString())
    }
  }

  QQC2.SpinBox {
    visible: field.opacityPath !== ""
    from: 0
    to: 100
    editable: true
    value: field.opacityPath === "" ? 0 : Math.round(Number(field.page.get(field.opacityPath)) * 100)
    onValueModified: field.page.set(field.opacityPath, value / 100)
    textFromValue: (v) => v + " %"
    valueFromText: (text) => parseInt(text) || 0
  }
}
