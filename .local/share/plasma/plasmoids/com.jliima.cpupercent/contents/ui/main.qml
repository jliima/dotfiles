import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

// Total CPU usage as a plain number ("12%"), from the same sensor as the System Monitor widgets.
PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    readonly property string percent: Math.round(cpu.value || 0) + "%"

    toolTipMainText: "CPU usage"
    toolTipSubText: percent

    Sensors.Sensor {
        id: cpu
        sensorId: "cpu/all/usage"
        updateRateLimit: 1500
    }

    fullRepresentation: Item {
        // Wide enough for "100%", so the panel does not jump as the number changes.
        Layout.minimumWidth: metrics.width + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth

        TextMetrics {
            id: metrics
            font: label.font
            text: "100%"
        }
        PlasmaComponents3.Label {
            id: label
            anchors.centerIn: parent
            text: root.percent
            // The same size as the Copilot and Claude usage numbers.
            font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.1)
            font.bold: true
            font.features: { "tnum": 1 }
        }
    }
}
