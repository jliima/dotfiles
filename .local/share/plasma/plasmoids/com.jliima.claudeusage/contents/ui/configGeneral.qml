import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_showSession: showSession.checked
    property alias cfg_showWeekly: showWeekly.checked
    property alias cfg_resetStyle: resetStyle.currentIndex
    property alias cfg_pollMinutes: pollMinutes.value

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: showSession
            Kirigami.FormData.label: "In the panel:"
            text: "Session usage (5 hours)"
        }
        QQC2.CheckBox {
            id: showWeekly
            text: "Weekly usage"
        }
        QQC2.ComboBox {
            id: resetStyle
            Kirigami.FormData.label: "Reset shown as:"
            model: ["Time left (2h13m, 3d 4h)", "Clock time (14:30, Thu 09:00)"]
        }
        QQC2.SpinBox {
            id: pollMinutes
            Kirigami.FormData.label: "Update every (minutes):"
            from: 1
            to: 60
        }
    }
}
