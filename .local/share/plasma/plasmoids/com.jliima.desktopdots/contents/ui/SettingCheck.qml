import QtQuick
import QtQuick.Controls as QQC2

QQC2.CheckBox {
  required property var page
  required property string path

  checked: page.get(path) === true
  onToggled: page.set(path, checked)
}
