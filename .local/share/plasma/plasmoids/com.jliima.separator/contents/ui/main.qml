import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

// A one pixel line across 60% of the panel's thickness, with a little room on both sides.
PlasmoidItem {
    id: root

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    fullRepresentation: Item {
        readonly property int room: Kirigami.Units.smallSpacing * 2 + 1
        Layout.minimumWidth: root.vertical ? -1 : room
        Layout.maximumWidth: root.vertical ? -1 : room
        Layout.minimumHeight: root.vertical ? room : -1
        Layout.maximumHeight: root.vertical ? room : -1

        Rectangle {
            anchors.centerIn: parent
            width: root.vertical ? parent.width * 0.6 : 1
            height: root.vertical ? 1 : parent.height * 0.6
            color: Kirigami.Theme.textColor
            opacity: 0.25
        }
    }
}
