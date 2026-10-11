import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

SettingsPage {
  id: page

  Kirigami.FormLayout {
    SettingCheck {
      Kirigami.FormData.label: "Programs:"
      text: "Show the programs open on each desktop"
      page: page
      path: "programs.show"
    }
    SettingCombo {
      Kirigami.FormData.label: "Show on:"
      page: page
      path: "programs.showOn"
      model: [
        { text: "Every desktop with windows", value: "all" },
        { text: "The current desktop only", value: "active" }
      ]
    }
    SettingCheck {
      text: "One icon per program, however many windows it has"
      page: page
      path: "programs.onePerApp"
    }
    SettingSpin {
      Kirigami.FormData.label: "Most icons per desktop:"
      page: page
      path: "programs.maxIcons"
      from: 0
      to: 30
      textFromValue: (v) => v === 0 ? "No limit" : String(v)
    }
    SettingCombo {
      Kirigami.FormData.label: "More than that:"
      page: page
      path: "programs.overflow"
      model: [
        { text: "Show +N", value: "count" },
        { text: "Show nothing", value: "none" }
      ]
    }
    SettingColor {
      Kirigami.FormData.label: "Color of +N:"
      page: page
      path: "programs.overflowColor"
    }

    Kirigami.Separator {
      Kirigami.FormData.isSection: true
      Kirigami.FormData.label: "Icons"
    }
    SettingSpin {
      Kirigami.FormData.label: "Icon size:"
      page: page
      path: "programs.iconSize"
      from: 6
      to: 64
      suffix: " px"
    }
    SettingSpin {
      Kirigami.FormData.label: "Gap between icons:"
      page: page
      path: "programs.iconSpacing"
      from: 0
      to: 60
      suffix: " px"
    }
    SettingSpin {
      Kirigami.FormData.label: "Opacity:"
      page: page
      path: "programs.iconOpacity"
      factor: 100
      from: 0
      to: 100
      suffix: " %"
    }
    SettingSpin {
      Kirigami.FormData.label: "Opacity of the focused program:"
      page: page
      path: "programs.activeIconOpacity"
      factor: 100
      from: 0
      to: 100
      suffix: " %"
    }
    SettingCheck {
      text: "Mark the focused program with a bar under its icon"
      page: page
      path: "programs.highlightFocused"
    }

    Kirigami.Separator {
      Kirigami.FormData.isSection: true
      Kirigami.FormData.label: "Pill"
    }
    SettingSpin {
      Kirigami.FormData.label: "Padding along:"
      page: page
      path: "programs.pill.paddingX"
      from: 0
      to: 60
      suffix: " px"
    }
    SettingSpin {
      Kirigami.FormData.label: "Padding across:"
      page: page
      path: "programs.pill.paddingY"
      from: 0
      to: 60
      suffix: " px"
    }
    SettingSpin {
      Kirigami.FormData.label: "Corner radius:"
      page: page
      path: "programs.pill.radius"
      from: -1
      to: 100
      textFromValue: (v) => v < 0 ? "Full pill" : v + " px"
    }
    SettingColor {
      Kirigami.FormData.label: "Color:"
      page: page
      path: "programs.pill.color"
      opacityPath: "programs.pill.opacity"
    }
    SettingColor {
      Kirigami.FormData.label: "Color on the current desktop:"
      page: page
      path: "programs.pill.activeColor"
      opacityPath: "programs.pill.activeOpacity"
    }
    SettingColor {
      Kirigami.FormData.label: "Border:"
      page: page
      path: "programs.pill.border"
      opacityPath: "programs.pill.borderOpacity"
    }
    SettingColor {
      Kirigami.FormData.label: "Border on the current desktop:"
      page: page
      path: "programs.pill.activeBorder"
      opacityPath: "programs.pill.activeBorderOpacity"
    }
    SettingSpin {
      Kirigami.FormData.label: "Border width:"
      page: page
      path: "programs.pill.borderWidth"
      from: 0
      to: 20
      suffix: " px"
    }
  }
}
