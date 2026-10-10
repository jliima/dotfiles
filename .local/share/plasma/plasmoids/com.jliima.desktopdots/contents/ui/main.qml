import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

// Desktop Dots: every virtual desktop as a circle, and optionally a pill of the programs open on it. The whole look is
// in a JSON file under ~/.config (see ConfigFile.qml and code/defaults.js), edited in the settings dialog or by hand;
// the widget follows the file live.
PlasmoidItem {
  id: root

  readonly property var cfg: store.config
  readonly property bool vertical: cfg.layout.orientation === "vertical"
      || (cfg.layout.orientation === "auto" && Plasmoid.formFactor === PlasmaCore.Types.Vertical)

  preferredRepresentation: fullRepresentation
  Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
  toolTipMainText: ""

  ConfigFile {
    id: store
    relativePath: Plasmoid.configuration.configFile
  }
  ThemeColors { id: themeColors }
  TaskManager.VirtualDesktopInfo { id: desktopInfo }
  TaskManager.ActivityInfo { id: activityInfo }

  function switchTo(id) {
    desktopInfo.requestActivate(id)
  }

  // The desktop `step` away from the current one, or the current one at the ends unless wrapping
  function step(delta) {
    var ids = desktopInfo.desktopIds
    var at = ids.indexOf(desktopInfo.currentDesktop)
    if (at < 0 || ids.length === 0) {
      return
    }
    var next = at + delta
    if (next < 0 || next >= ids.length) {
      if (!cfg.behavior.wrap) {
        return
      }
      next = (next + ids.length) % ids.length
    }
    switchTo(ids[next])
  }

  fullRepresentation: Item {
    id: bar

    readonly property real length: (root.vertical ? row.implicitHeight : row.implicitWidth)
        + 2 * root.cfg.layout.margin
    Layout.minimumWidth: root.vertical ? -1 : length
    Layout.preferredWidth: root.vertical ? -1 : length
    Layout.maximumWidth: root.vertical ? -1 : length
    Layout.minimumHeight: root.vertical ? length : -1
    Layout.preferredHeight: root.vertical ? length : -1
    Layout.maximumHeight: root.vertical ? length : -1

    Grid {
      id: row
      anchors.centerIn: parent
      rows: root.vertical ? -1 : 1
      columns: root.vertical ? 1 : -1
      spacing: root.cfg.layout.spacing
      horizontalItemAlignment: Grid.AlignHCenter
      verticalItemAlignment: Grid.AlignVCenter

      Repeater {
        model: desktopInfo.desktopIds
        delegate: DesktopItem {
          required property int index
          required property var modelData
          cfg: root.cfg
          colors: themeColors
          desktopId: modelData
          desktopName: desktopInfo.desktopNames[index]
          desktopIndex: index
          isActive: desktopInfo.currentDesktop === modelData
          vertical: root.vertical
          activities: activityInfo
          screenGeometry: Plasmoid.containment.screenGeometry
          onSwitchTo: (id) => root.switchTo(id)
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.NoButton
      enabled: root.cfg.behavior.wheel
      onWheel: (wheel) => {
        var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
        if (delta !== 0) {
          root.step(delta > 0 ? -1 : 1)
        }
      }
    }
  }
}
