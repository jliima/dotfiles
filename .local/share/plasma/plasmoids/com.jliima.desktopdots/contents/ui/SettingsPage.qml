import QtQuick
import org.kde.kcmutils as KCM
import "../code/defaults.js" as Defaults

// The base of every settings page. It edits a working copy of the config file; Apply writes the file (the widget
// follows it live), so there is nothing in Plasma's own settings except the file's path.
KCM.SimpleKCM {
  id: page

  // Plasma sets these from main.xml
  property string cfg_configFile: "desktopdots/config.json"
  property string cfg_configFileDefault: "desktopdots/config.json"

  property bool unsavedChanges: false
  property var work: Defaults.effective({})
  property bool ready: false

  ConfigFile {
    id: store
    relativePath: page.cfg_configFile
    onLoadedChanged: if (loaded && !page.ready) page.reset()
  }

  readonly property string filePath: store.path

  // The working copy starts as what the file holds (with the defaults under it)
  function reset() {
    work = Defaults.clone(store.config)
    loadedPath = cfg_configFile
    ready = true
    unsavedChanges = false
  }

  function restoreDefaults() {
    work = Defaults.effective({})
    unsavedChanges = true
  }

  function get(path) {
    var value = work
    var parts = path.split(".")
    for (var i = 0; i < parts.length; ++i) {
      value = value === undefined ? undefined : value[parts[i]]
    }
    return value
  }

  function set(path, value) {
    var copy = Defaults.clone(work)
    var parts = path.split(".")
    var node = copy
    for (var i = 0; i < parts.length - 1; ++i) {
      node = node[parts[i]]
    }
    node[parts[parts.length - 1]] = value
    work = copy
    unsavedChanges = true
  }

  // Plasma calls this on Apply and OK
  function saveConfig() {
    if (ready && (unsavedChanges || page.cfg_configFile !== loadedPath)) {
      store.write(work)
    }
    unsavedChanges = false
  }

  // The file this page read its working copy from; a new path in the Behavior page gets the copy written to it
  property string loadedPath: ""
}
