import QtQuick
import QtQuick.Controls as QQC2

// A choice of the config; model is a list of { text, value }.
QQC2.ComboBox {
  required property var page
  required property string path

  textRole: "text"
  valueRole: "value"
  readonly property var current: page.get(path)

  // Set from code: a binding is lost when the model is assigned after it
  function sync() {
    currentIndex = indexOfValue(current)
  }
  onCurrentChanged: sync()
  onModelChanged: sync()
  Component.onCompleted: sync()
  onActivated: page.set(path, currentValue)
}
