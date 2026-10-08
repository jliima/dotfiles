import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_minimumLength: minimumLength.value
    property alias cfg_onlyCurrentDesktop: onlyCurrentDesktop.checked
    property alias cfg_onlyCurrentActivity: onlyCurrentActivity.checked

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: minimumLength
            Kirigami.FormData.label: "Minimum length (px):"
            from: 0
            to: 4000
            stepSize: 10
        }
        QQC2.CheckBox {
            id: onlyCurrentDesktop
            Kirigami.FormData.label: "Show:"
            text: "Only windows on the current desktop"
        }
        QQC2.CheckBox {
            id: onlyCurrentActivity
            text: "Only windows in the current activity"
        }
    }
}
