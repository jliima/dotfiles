import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

SettingsPage {
  id: page

  Kirigami.FormLayout {
    SettingSpin {
      Kirigami.FormData.label: "Circle size:"
      page: page
      path: "circles.size"
      from: 2
      to: 80
      suffix: " px"
    }
    SettingSpin {
      Kirigami.FormData.label: "Border width:"
      page: page
      path: "circles.borderWidth"
      from: 0
      to: 20
      suffix: " px"
    }
    SettingSpin {
      Kirigami.FormData.label: "Gap between desktops:"
      page: page
      path: "layout.spacing"
      from: 0
      to: 200
      suffix: " px"
    }
    SettingSpin {
      Kirigami.FormData.label: "Space at both ends:"
      page: page
      path: "layout.margin"
      from: 0
      to: 200
      suffix: " px"
    }
    SettingCombo {
      Kirigami.FormData.label: "Text inside:"
      page: page
      path: "circles.label"
      model: [
        { text: "Nothing", value: "none" },
        { text: "Desktop number", value: "number" },
        { text: "Desktop name", value: "name" }
      ]
    }
    SettingSpin {
      Kirigami.FormData.label: "Text size:"
      page: page
      path: "circles.labelSize"
      from: 4
      to: 40
      suffix: " px"
    }
    SettingColor {
      Kirigami.FormData.label: "Text color:"
      page: page
      path: "circles.labelColor"
    }
    SettingSpin {
      Kirigami.FormData.label: "Windows that fill a level circle:"
      page: page
      path: "circles.levelMax"
      from: 1
      to: 30
    }
    SettingSpin {
      Kirigami.FormData.label: "Animation:"
      page: page
      path: "circles.animation"
      from: 0
      to: 2000
      stepSize: 10
      suffix: " ms"
    }

    Kirigami.Separator {
      Kirigami.FormData.isSection: true
      Kirigami.FormData.label: "Current desktop"
    }
    SettingCombo {
      Kirigami.FormData.label: "Fill:"
      page: page
      path: "circles.active.fill"
      model: [
          { text: "Solid", value: "solid" },
          { text: "Outline", value: "outline" },
          { text: "Ring with a dot", value: "dot" },
          { text: "Thick ring", value: "ring" },
          { text: "Half", value: "half" },
          { text: "Level (by windows)", value: "level" },
          { text: "Gradient", value: "gradient" },
          { text: "Nothing", value: "none" }
        ]
    }
    SettingColor {
      Kirigami.FormData.label: "Color:"
      page: page
      path: "circles.active.color"
    }
    SettingColor {
      Kirigami.FormData.label: "Border:"
      page: page
      path: "circles.active.border"
    }
    SettingSpin {
      Kirigami.FormData.label: "Opacity:"
      page: page
      path: "circles.active.opacity"
      factor: 100
      from: 0
      to: 100
      suffix: " %"
    }
    SettingSpin {
      Kirigami.FormData.label: "Size:"
      page: page
      path: "circles.active.scale"
      factor: 100
      from: 30
      to: 300
      suffix: " %"
    }

    Kirigami.Separator {
      Kirigami.FormData.isSection: true
      Kirigami.FormData.label: "Desktop with windows"
    }
    SettingCombo {
      Kirigami.FormData.label: "Fill:"
      page: page
      path: "circles.occupied.fill"
      model: [
          { text: "Solid", value: "solid" },
          { text: "Outline", value: "outline" },
          { text: "Ring with a dot", value: "dot" },
          { text: "Thick ring", value: "ring" },
          { text: "Half", value: "half" },
          { text: "Level (by windows)", value: "level" },
          { text: "Gradient", value: "gradient" },
          { text: "Nothing", value: "none" }
        ]
    }
    SettingColor {
      Kirigami.FormData.label: "Color:"
      page: page
      path: "circles.occupied.color"
    }
    SettingColor {
      Kirigami.FormData.label: "Border:"
      page: page
      path: "circles.occupied.border"
    }
    SettingSpin {
      Kirigami.FormData.label: "Opacity:"
      page: page
      path: "circles.occupied.opacity"
      factor: 100
      from: 0
      to: 100
      suffix: " %"
    }
    SettingSpin {
      Kirigami.FormData.label: "Size:"
      page: page
      path: "circles.occupied.scale"
      factor: 100
      from: 30
      to: 300
      suffix: " %"
    }

    Kirigami.Separator {
      Kirigami.FormData.isSection: true
      Kirigami.FormData.label: "Empty desktop"
    }
    SettingCombo {
      Kirigami.FormData.label: "Fill:"
      page: page
      path: "circles.empty.fill"
      model: [
          { text: "Solid", value: "solid" },
          { text: "Outline", value: "outline" },
          { text: "Ring with a dot", value: "dot" },
          { text: "Thick ring", value: "ring" },
          { text: "Half", value: "half" },
          { text: "Level (by windows)", value: "level" },
          { text: "Gradient", value: "gradient" },
          { text: "Nothing", value: "none" }
        ]
    }
    SettingColor {
      Kirigami.FormData.label: "Color:"
      page: page
      path: "circles.empty.color"
    }
    SettingColor {
      Kirigami.FormData.label: "Border:"
      page: page
      path: "circles.empty.border"
    }
    SettingSpin {
      Kirigami.FormData.label: "Opacity:"
      page: page
      path: "circles.empty.opacity"
      factor: 100
      from: 0
      to: 100
      suffix: " %"
    }
    SettingSpin {
      Kirigami.FormData.label: "Size:"
      page: page
      path: "circles.empty.scale"
      factor: 100
      from: 30
      to: 300
      suffix: " %"
    }

    Kirigami.Separator {
      Kirigami.FormData.isSection: true
      Kirigami.FormData.label: "Desktop with a window that wants attention"
    }
    SettingCombo {
      Kirigami.FormData.label: "Fill:"
      page: page
      path: "circles.urgent.fill"
      model: [
          { text: "Solid", value: "solid" },
          { text: "Outline", value: "outline" },
          { text: "Ring with a dot", value: "dot" },
          { text: "Thick ring", value: "ring" },
          { text: "Half", value: "half" },
          { text: "Level (by windows)", value: "level" },
          { text: "Gradient", value: "gradient" },
          { text: "Nothing", value: "none" }
        ]
    }
    SettingColor {
      Kirigami.FormData.label: "Color:"
      page: page
      path: "circles.urgent.color"
    }
    SettingColor {
      Kirigami.FormData.label: "Border:"
      page: page
      path: "circles.urgent.border"
    }
    SettingSpin {
      Kirigami.FormData.label: "Opacity:"
      page: page
      path: "circles.urgent.opacity"
      factor: 100
      from: 0
      to: 100
      suffix: " %"
    }
    SettingSpin {
      Kirigami.FormData.label: "Size:"
      page: page
      path: "circles.urgent.scale"
      factor: 100
      from: 30
      to: 300
      suffix: " %"
    }

    Kirigami.Separator {
      Kirigami.FormData.isSection: true
      Kirigami.FormData.label: "Under the mouse"
    }
    SettingSpin {
      Kirigami.FormData.label: "Opacity:"
      page: page
      path: "circles.hover.opacity"
      factor: 100
      from: 0
      to: 100
      suffix: " %"
    }
    SettingSpin {
      Kirigami.FormData.label: "Size:"
      page: page
      path: "circles.hover.scale"
      factor: 100
      from: 30
      to: 300
      suffix: " %"
    }
  }
}
