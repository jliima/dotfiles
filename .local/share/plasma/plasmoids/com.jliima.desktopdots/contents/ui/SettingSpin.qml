import QtQuick
import QtQuick.Controls as QQC2

// A number of the config. factor turns the stored value into the shown one (0.35 shown as 35 with factor 100).
QQC2.SpinBox {
  id: spin

  required property var page
  required property string path
  property real factor: 1

  editable: true
  value: Math.round(Number(page.get(path)) * factor)
  onValueModified: page.set(path, value / factor)
  textFromValue: (v) => String(v) + suffix
  valueFromText: (text) => parseInt(text) || 0
  property string suffix: ""
}
