import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

SettingsPage {
  id: page

  Kirigami.FormLayout {
    SettingCheck {
      Kirigami.FormData.label: "Mouse:"
      text: "A click on a desktop switches to it"
      page: page
      path: "behavior.clickSwitches"
    }
    SettingCheck {
      text: "A click on a program icon focuses the program"
      page: page
      path: "behavior.iconClickFocuses"
    }
    SettingCheck {
      text: "Scrolling over the widget changes the desktop"
      page: page
      path: "behavior.wheel"
    }
    SettingCheck {
      text: "Scrolling goes round from the last desktop to the first"
      page: page
      path: "behavior.wrap"
    }
    SettingCheck {
      text: "Show a tooltip with the desktop and its programs"
      page: page
      path: "behavior.tooltip"
    }

    Kirigami.Separator {
      Kirigami.FormData.isSection: true
      Kirigami.FormData.label: "Windows"
    }
    SettingCheck {
      Kirigami.FormData.label: "Only:"
      text: "Windows of the current activity"
      page: page
      path: "behavior.currentActivityOnly"
    }
    SettingCheck {
      text: "Windows on the screen of this panel"
      page: page
      path: "behavior.currentScreenOnly"
    }

    Kirigami.Separator {
      Kirigami.FormData.isSection: true
      Kirigami.FormData.label: "Layout"
    }
    SettingCombo {
      Kirigami.FormData.label: "Direction:"
      page: page
      path: "layout.orientation"
      model: [
        { text: "Follow the panel", value: "auto" },
        { text: "Horizontal", value: "horizontal" },
        { text: "Vertical", value: "vertical" }
      ]
    }

    Kirigami.Separator {
      Kirigami.FormData.isSection: true
      Kirigami.FormData.label: "Settings file"
    }
    QQC2.TextField {
      Kirigami.FormData.label: "Path in your config folder:"
      text: page.cfg_configFile
      onTextEdited: page.cfg_configFile = text
      Layout.preferredWidth: Kirigami.Units.gridUnit * 16
    }
    QQC2.Label {
      text: "The look is saved in " + page.filePath
          + ". You can edit that file by hand; the widget follows it. Widgets with the same path share one look."
      wrapMode: Text.WordWrap
      Layout.preferredWidth: Kirigami.Units.gridUnit * 20
      opacity: 0.7
    }
    QQC2.Button {
      text: "Restore all defaults"
      icon.name: "edit-undo"
      onClicked: page.restoreDefaults()
    }
  }
}
