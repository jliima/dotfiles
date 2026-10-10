import QtQuick
import org.kde.plasma.configuration

ConfigModel {
  ConfigCategory {
    name: "Circles"
    icon: "draw-ellipse"
    source: "configCircles.qml"
  }
  ConfigCategory {
    name: "Programs"
    icon: "applications-all"
    source: "configPrograms.qml"
  }
  ConfigCategory {
    name: "Behavior"
    icon: "configure"
    source: "configBehavior.qml"
  }
}
