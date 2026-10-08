import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

// CPU usage: a bar per core with the total over it in the panel, the same with every core's number in the popup.
// Colours come from the colour scheme (Themer): bars in the accent, text in the text colour.
PlasmoidItem {
  id: root

  Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
  readonly property real total: totalSensor.value || 0
  readonly property string percent: Math.round(total) + "%"
  // Per-core usage, refreshed with the sensors; the core count differs per machine.
  property var cores: []

  toolTipMainText: "CPU usage"
  toolTipSubText: percent

  Sensors.Sensor {
    id: totalSensor
    sensorId: "cpu/all/usage"
    updateRateLimit: 1500
  }
  Sensors.Sensor {
    id: countSensor
    sensorId: "cpu/all/coreCount"
  }
  Instantiator {
    id: coreSensors
    model: countSensor.value || 0
    delegate: Sensors.Sensor {
      required property int index
      sensorId: "cpu/cpu" + index + "/usage"
      updateRateLimit: 1500
    }
  }
  Timer {
    interval: 1500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      var values = []
      for (var i = 0; i < coreSensors.count; ++i) {
        var s = coreSensors.objectAt(i)
        values.push(s ? (s.value || 0) : 0)
      }
      root.cores = values
    }
  }

  component Bars: Row {
    id: bars
    property real barWidth: 4
    spacing: 1
    Repeater {
      model: root.cores.length
      delegate: Item {
        required property int index
        width: bars.barWidth
        height: bars.height
        Rectangle {
          anchors.fill: parent
          color: Kirigami.Theme.textColor
          opacity: 0.08
        }
        Rectangle {
          anchors.bottom: parent.bottom
          width: parent.width
          height: Math.round(parent.height * Math.min(100, root.cores[index] || 0) / 100)
          color: Kirigami.Theme.focusColor
          Behavior on height { NumberAnimation { duration: Kirigami.Units.shortDuration } }
        }
      }
    }
  }

  compactRepresentation: MouseArea {
    // At least as wide as "100%", so few cores still fit the number.
    Layout.minimumWidth: Math.max(bars.implicitWidth, metrics.width + Kirigami.Units.smallSpacing * 2)
    Layout.preferredWidth: Layout.minimumWidth
    onClicked: root.expanded = !root.expanded

    TextMetrics {
      id: metrics
      font: label.font
      text: "100%"
    }
    Bars {
      id: bars
      anchors.centerIn: parent
      height: parent.height - Kirigami.Units.smallSpacing * 2
    }
    PlasmaComponents3.Label {
      id: label
      anchors.centerIn: parent
      text: root.percent
      opacity: 0.8
      // The outline keeps the number readable over full bars.
      style: Text.Outline
      styleColor: Kirigami.Theme.backgroundColor
      // The same size as the Copilot and Claude usage numbers.
      font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.1)
      font.bold: true
      font.features: { "tnum": 1 }
    }
  }

  fullRepresentation: Item {
    Layout.minimumWidth: Kirigami.Units.gridUnit * 18
    Layout.minimumHeight: column.implicitHeight + Kirigami.Units.largeSpacing * 2
    Layout.preferredHeight: Layout.minimumHeight

    ColumnLayout {
      id: column
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: Kirigami.Units.largeSpacing
      spacing: Kirigami.Units.largeSpacing

      RowLayout {
        Layout.fillWidth: true
        Kirigami.Heading { level: 3; text: "CPU Usage" }
        Item { Layout.fillWidth: true }
        PlasmaComponents3.Label { text: "Total"; opacity: 0.8 }
        PlasmaComponents3.Label {
          text: root.percent
          font.bold: true
          font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.1)
          font.features: { "tnum": 1 }
        }
      }
      PlasmaComponents3.ProgressBar {
        Layout.fillWidth: true
        from: 0; to: 100
        value: root.total
      }

      Kirigami.Separator { Layout.fillWidth: true }

      Bars {
        id: popupBars
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: Kirigami.Units.gridUnit * 5
        barWidth: Math.max(4, Math.floor(column.width / Math.max(1, root.cores.length)) - spacing)
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 4
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: 0
        Repeater {
          model: root.cores.length
          delegate: RowLayout {
            required property int index
            Layout.fillWidth: true
            PlasmaComponents3.Label {
              text: (index + 1)
              opacity: 0.6
              font.features: { "tnum": 1 }
            }
            Item { Layout.fillWidth: true }
            PlasmaComponents3.Label {
              text: Math.round(root.cores[index] || 0) + "%"
              font.features: { "tnum": 1 }
            }
          }
        }
      }
    }
  }
}
