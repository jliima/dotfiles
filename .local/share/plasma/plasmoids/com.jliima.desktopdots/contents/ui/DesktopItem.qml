import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import org.kde.kitemmodels as KItemModels

// One virtual desktop: its circle and, when the programs option is on, the pill with an icon for every program that
// has a window on it. Position, sizes and colors all come from the config.
Item {
  id: cell

  required property var cfg
  required property var colors
  required property var desktopId
  required property string desktopName
  required property int desktopIndex
  required property bool isActive
  required property bool vertical          // the panel runs vertically
  required property var activities
  property rect screenGeometry: Qt.rect(0, 0, 0, 0)

  signal switchTo(var id)

  readonly property var circ: cfg.circles
  readonly property var prog: cfg.programs
  readonly property var pill: cfg.programs.pill
  readonly property real gap: cfg.layout.pillGap

  // Where the pill sits: along the panel (after, before, inside) or across it (below, above)
  readonly property string pos: cfg.layout.pillPosition
  readonly property bool inside: pos === "inside"
  readonly property bool pillFirst: pos === "before" || pos === "above"
  readonly property bool along: pos === "after" || pos === "before" || pos === "inside"
  readonly property bool flowH: along !== vertical   // circle and pill side by side

  readonly property int maxIcons: prog.maxIcons
  readonly property int shown: maxIcons > 0 ? Math.min(here.count, maxIcons) : here.count
  readonly property int hiddenCount: here.count - shown
  readonly property bool hasPill: prog.show && here.count > 0 && (prog.showOn === "all" || isActive)
  property bool urgent: false

  readonly property string stateName: urgent ? "urgent" : isActive ? "active" : here.count > 0 ? "occupied" : "empty"
  readonly property var look: circ[stateName]
  readonly property bool hovered: mouse.containsMouse

  readonly property real cs: circ.size
  readonly property real padX: pill.paddingX
  readonly property real padY: pill.paddingY
  readonly property real iconsW: icons.implicitWidth
  readonly property real iconsH: icons.implicitHeight
  // The pill with the circle in it counts the circle too
  readonly property real pillW: !hasPill ? 0 : inside && flowH ? padX * 2 + cs + gap + iconsW
                                : inside ? Math.max(cs, iconsW) + padX * 2 : iconsW + padX * 2
  readonly property real pillH: !hasPill ? 0 : inside && !flowH ? padY * 2 + cs + gap + iconsH
                                : inside ? Math.max(cs, iconsH) + padY * 2 : iconsH + padY * 2

  implicitWidth: Math.round(!hasPill ? cs : inside ? pillW : flowH ? cs + gap + pillW : Math.max(cs, pillW))
  implicitHeight: Math.round(!hasPill ? cs : inside ? pillH : flowH ? Math.max(cs, pillH) : cs + gap + pillH)
  width: implicitWidth
  height: implicitHeight

  TaskManager.TasksModel {
    id: tasks
    filterByVirtualDesktop: true
    virtualDesktop: cell.desktopId
    filterByActivity: cell.cfg.behavior.currentActivityOnly
    activity: cell.activities.currentActivity
    filterByScreen: cell.cfg.behavior.currentScreenOnly
    screenGeometry: cell.screenGeometry
    groupMode: cell.prog.onePerApp ? TaskManager.TasksModel.GroupApplications : TaskManager.TasksModel.GroupDisabled
    groupInline: false
    sortMode: TaskManager.TasksModel.SortManual
  }

  // TasksModel lets a window that wants attention through on every desktop; only its own desktops should show it
  KItemModels.KSortFilterProxyModel {
    id: here
    sourceModel: tasks
    filterRowCallback: (sourceRow, sourceParent) => {
      const index = tasks.index(sourceRow, 0, sourceParent)
      if (tasks.data(index, TaskManager.AbstractTasksModel.IsOnAllVirtualDesktops)) {
        return true
      }
      const desktops = tasks.data(index, TaskManager.AbstractTasksModel.VirtualDesktops)
      return !desktops || desktops.length === 0 || desktops.indexOf(cell.desktopId) >= 0
    }
    onCountChanged: cell.refreshUrgent()
    onDataChanged: cell.refreshUrgent()
  }

  // A window that wants attention marks the desktop it lives on
  function refreshUrgent() {
    var found = false
    for (var i = 0; i < here.count; ++i) {
      if (here.data(here.index(i, 0), TaskManager.AbstractTasksModel.IsDemandingAttention)) {
        found = true
        break
      }
    }
    urgent = found
  }

  function programNames() {
    var names = []
    for (var i = 0; i < here.count; ++i) {
      names.push(here.data(here.index(i, 0), Qt.DisplayRole))
    }
    return names
  }

  // ---- the desktop as a whole: click, hover, tooltip ----
  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    onClicked: if (cell.cfg.behavior.clickSwitches) cell.switchTo(cell.desktopId)
  }

  PlasmaCore.ToolTipArea {
    anchors.fill: parent
    enabled: cell.cfg.behavior.tooltip
    mainText: cell.desktopName
    subText: here.count > 0 ? cell.programNames().join("\n") : "No windows"
  }

  // ---- the pill ----
  Rectangle {
    id: pillBox
    visible: cell.hasPill
    width: cell.pillW
    height: cell.pillH
    x: Math.round(cell.inside ? 0 : cell.flowH ? (cell.pillFirst ? 0 : cell.cs + cell.gap)
                                                : (cell.width - width) / 2)
    y: Math.round(cell.inside ? 0 : cell.flowH ? (cell.height - height) / 2
                                                : (cell.pillFirst ? 0 : cell.cs + cell.gap))
    radius: cell.pill.radius < 0 ? Math.min(width, height) / 2 : cell.pill.radius
    color: cell.isActive ? cell.colors.resolve(cell.pill.activeColor, cell.pill.activeOpacity)
                         : cell.colors.resolve(cell.pill.color, cell.pill.opacity)
    border.width: cell.pill.borderWidth
    border.color: cell.isActive ? cell.colors.resolve(cell.pill.activeBorder, cell.pill.activeBorderOpacity)
                                : cell.colors.resolve(cell.pill.border, cell.pill.borderOpacity)
    Behavior on color { ColorAnimation { duration: cell.circ.animation } }

    Grid {
      id: icons
      // The circle takes the first slot of an "inside" pill
      x: cell.inside ? (cell.flowH ? cell.padX + cell.cs + cell.gap : (parent.width - width) / 2) : cell.padX
      y: cell.inside ? (cell.flowH ? (parent.height - height) / 2 : cell.padY + cell.cs + cell.gap) : cell.padY
      rows: cell.vertical ? -1 : 1
      columns: cell.vertical ? 1 : -1
      spacing: cell.prog.iconSpacing

      Repeater {
        model: here
        delegate: Item {
          id: app
          required property int index
          required property var model
          visible: cell.maxIcons <= 0 || index < cell.maxIcons
          width: cell.prog.iconSize
          height: cell.prog.iconSize

          Kirigami.Icon {
            anchors.fill: parent
            source: app.model.decoration
            active: appMouse.containsMouse
            opacity: app.model.IsActive === true ? cell.prog.activeIconOpacity : cell.prog.iconOpacity
            Behavior on opacity { NumberAnimation { duration: cell.circ.animation } }
          }
          Rectangle {
            visible: cell.prog.highlightFocused && app.model.IsActive === true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: -1
            width: Math.max(4, parent.width * 0.5)
            height: 2
            radius: 1
            color: cell.colors.resolve(cell.look.color)
          }
          MouseArea {
            id: appMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              if (cell.cfg.behavior.iconClickFocuses) {
                tasks.requestActivate(here.mapToSource(here.index(app.index, 0)))
              } else if (cell.cfg.behavior.clickSwitches) {
                cell.switchTo(cell.desktopId)
              }
            }
          }
          PlasmaCore.ToolTipArea {
            anchors.fill: parent
            enabled: cell.cfg.behavior.tooltip
            mainText: app.model.display
            subText: cell.desktopName
          }
        }
      }

      Text {
        visible: cell.hiddenCount > 0 && cell.prog.overflow === "count"
        height: cell.prog.iconSize
        verticalAlignment: Text.AlignVCenter
        text: "+" + cell.hiddenCount
        color: cell.colors.resolve("theme:text", 0.8)
        font.pixelSize: Math.max(8, cell.prog.iconSize * 0.6)
        font.bold: true
      }
    }
  }

  // ---- the circle ----
  Dot {
    id: dot
    x: Math.round(cell.inside && cell.hasPill
        ? (cell.flowH ? cell.padX : (cell.width - width) / 2)
        : cell.flowH ? (cell.pillFirst && cell.hasPill ? cell.pillW + cell.gap : 0) : (cell.width - width) / 2)
    y: Math.round(cell.inside && cell.hasPill
        ? (cell.flowH ? (cell.height - height) / 2 : cell.padY)
        : cell.flowH ? (cell.height - height) / 2 : (cell.pillFirst && cell.hasPill ? cell.pillH + cell.gap : 0))
    size: cell.cs
    fill: cell.look.fill
    color: cell.colors.resolve(cell.look.color)
    borderColor: cell.colors.resolve(cell.look.border)
    borderWidth: cell.circ.borderWidth
    level: Math.min(1, here.count / Math.max(1, cell.circ.levelMax))
    label: cell.circ.label === "number" ? String(cell.desktopIndex + 1)
         : cell.circ.label === "name" ? cell.desktopName : ""
    labelColor: cell.colors.resolve(cell.circ.labelColor)
    labelSize: cell.circ.labelSize
    animation: cell.circ.animation
    opacity: cell.hovered ? cell.circ.hover.opacity : cell.look.opacity
    scale: cell.look.scale * (cell.hovered ? cell.circ.hover.scale : 1)
    Behavior on opacity { NumberAnimation { duration: cell.circ.animation } }
    Behavior on scale { NumberAnimation { duration: cell.circ.animation; easing.type: Easing.OutCubic } }
  }
}
