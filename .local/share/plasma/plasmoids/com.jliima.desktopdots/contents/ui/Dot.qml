import QtQuick

// One circle. fill says how it is filled: solid, outline, dot (a ring with a dot in it), ring (a thick ring), half,
// level (filled from the bottom up to `level`, 0 to 1), gradient or none.
Item {
  id: dot

  property real size: 12
  property string fill: "solid"
  property color color: "white"
  property color borderColor: "white"
  property real borderWidth: 2
  property real level: 0
  property string label: ""
  property color labelColor: "black"
  property real labelSize: 8
  property int animation: 140

  width: size
  height: size

  readonly property real ringWidth: fill === "none" ? 0
      : fill === "ring" ? Math.max(borderWidth, size * 0.3) : borderWidth

  Behavior on color { ColorAnimation { duration: dot.animation } }
  Behavior on borderColor { ColorAnimation { duration: dot.animation } }
  Behavior on level { NumberAnimation { duration: dot.animation } }

  // The disc and its ring
  Rectangle {
    anchors.fill: parent
    radius: width / 2
    color: dot.fill === "solid" ? dot.color : "transparent"
    border.width: dot.ringWidth
    border.color: dot.borderColor
    gradient: dot.fill === "gradient" ? gradientFill : null
  }
  Gradient {
    id: gradientFill
    GradientStop { position: 0; color: Qt.lighter(dot.color, 1.4) }
    GradientStop { position: 1; color: Qt.darker(dot.color, 1.3) }
  }

  // dot: a smaller disc in the middle
  Rectangle {
    visible: dot.fill === "dot"
    anchors.centerIn: parent
    width: Math.max(2, dot.size * 0.42)
    height: width
    radius: width / 2
    color: dot.color
  }

  // half: the left half filled
  Item {
    visible: dot.fill === "half"
    width: dot.size / 2
    height: dot.size
    clip: true
    Rectangle {
      width: dot.size
      height: dot.size
      radius: width / 2
      color: dot.color
    }
  }

  // level: filled from the bottom
  Item {
    visible: dot.fill === "level"
    anchors.bottom: parent.bottom
    width: dot.size
    height: dot.size * Math.min(1, Math.max(0, dot.level))
    clip: true
    Rectangle {
      anchors.bottom: parent.bottom
      width: dot.size
      height: dot.size
      radius: width / 2
      color: dot.color
    }
  }

  Text {
    anchors.centerIn: parent
    visible: dot.label !== ""
    text: dot.label
    color: dot.labelColor
    font.pixelSize: dot.labelSize
    font.bold: true
  }
}
