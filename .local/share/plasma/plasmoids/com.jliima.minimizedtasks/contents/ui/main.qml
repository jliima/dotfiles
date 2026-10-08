import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

// The icons of the minimized windows, centered in a widget that is never shorter than minimumLength, so a panel that
// fits its content stays easy to hit. Click restores a window, middle-click closes it.
PlasmoidItem {
    id: root

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int minimumLength: Plasmoid.configuration.minimumLength

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    TaskManager.VirtualDesktopInfo { id: desktopInfo }
    TaskManager.ActivityInfo { id: activityInfo }

    TaskManager.TasksModel {
        id: tasks
        filterNotMinimized: true
        filterByVirtualDesktop: Plasmoid.configuration.onlyCurrentDesktop
        virtualDesktop: desktopInfo.currentDesktop
        filterByActivity: Plasmoid.configuration.onlyCurrentActivity
        activity: activityInfo.currentActivity
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortManual
    }

    fullRepresentation: Item {
        id: bar
        readonly property int thickness: root.vertical ? width : height
        readonly property int length: Math.max(root.minimumLength, (root.vertical ? icons.implicitHeight
                                                                               : icons.implicitWidth))
        Layout.minimumWidth: root.vertical ? -1 : length
        Layout.preferredWidth: root.vertical ? -1 : length
        Layout.maximumWidth: root.vertical ? -1 : length
        Layout.minimumHeight: root.vertical ? length : -1
        Layout.preferredHeight: root.vertical ? length : -1
        Layout.maximumHeight: root.vertical ? length : -1

        Grid {
            id: icons
            anchors.centerIn: parent
            rows: root.vertical ? -1 : 1
            columns: root.vertical ? 1 : -1
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: tasks
                delegate: MouseArea {
                    id: task
                    required property int index
                    required property var decoration
                    required property string display

                    width: bar.thickness
                    height: bar.thickness
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: (mouse) => {
                        const idx = tasks.makeModelIndex(index)
                        if (mouse.button === Qt.MiddleButton) {
                            tasks.requestClose(idx)
                        } else {
                            tasks.requestActivate(idx)
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing / 2
                        radius: Kirigami.Units.cornerRadius
                        color: Kirigami.Theme.highlightColor
                        opacity: task.containsMouse ? 0.25 : 0
                    }
                    Kirigami.Icon {
                        anchors.fill: parent
                        anchors.margins: Math.round(parent.height * 0.08)
                        source: task.decoration
                        opacity: 0.85
                    }
                    PlasmaCore.ToolTipArea {
                        anchors.fill: parent
                        mainText: task.display
                        subText: "Click to restore, middle-click to close"
                    }
                }
            }
        }
    }
}
