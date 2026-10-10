import QtQuick
import QtCore
import Qt.labs.folderlistmodel
import org.kde.plasma.plasma5support as P5Support
import "../code/defaults.js" as Defaults

// The widget's look, kept in a JSON file under ~/.config. Reads it (and again whenever it changes, so a script or a
// theme tool can restyle the widget live), and writes it for the settings dialog.
Item {
  id: store

  // Relative to the user's config folder (~/.config).
  property string relativePath: "desktopdots/config.json"

  readonly property string configHome: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation)
      .toString().replace(/^file:\/\//, "")
  readonly property string path: configHome + "/" + relativePath
  readonly property string dir: path.substring(0, path.lastIndexOf("/"))
  readonly property string fileName: path.substring(path.lastIndexOf("/") + 1)

  // What the file holds, and the effective config (defaults under it).
  property var user: ({})
  readonly property var config: Defaults.effective(user)
  property bool fileExists: false
  property bool loaded: false
  property string error: ""

  function quote(text) {
    return "'" + String(text).replace(/'/g, "'\\''") + "'"
  }

  function reload() {
    reloadTimer.restart()
  }

  function readNow() {
    // The sources must wrap: the executable engine keeps every source name it has seen.
    store.seq = (store.seq + 1) % 8
    exec.connectSource("cat " + quote(path) + " # read " + store.seq)
  }

  // Writes the whole config (an object) as pretty JSON. The file is replaced atomically, behind a link if it is one
  // (a dotfiles setup links it), so the link stays.
  function write(object) {
    var text = JSON.stringify(object, null, 2) + "\n"
    var encoded = Qt.btoa(unescape(encodeURIComponent(text)))
    store.seq = (store.seq + 1) % 8
    var target = "\"$(readlink -f " + quote(path) + ")\""
    exec.connectSource("mkdir -p " + quote(dir) + " && t=" + target + " && printf %s '" + encoded
        + "' | base64 -d > \"$t.tmp\" && mv \"$t.tmp\" \"$t\" # write " + store.seq)
    // Show it at once; the file watcher reads it back a moment later.
    store.user = object
    store.fileExists = true
  }

  property int seq: 0

  P5Support.DataSource {
    id: exec
    engine: "executable"
    connectedSources: []
    onNewData: (sourceName, data) => {
      disconnectSource(sourceName)
      if (sourceName.indexOf("# read") === -1) {
        if (data["exit code"] !== 0) {
          store.error = "could not write " + store.path
        }
        return
      }
      store.loaded = true
      if (data["exit code"] !== 0) {
        store.fileExists = false
        store.user = ({})
        store.error = ""
        return
      }
      try {
        var parsed = JSON.parse(data["stdout"])
        store.user = Defaults.isObject(parsed) ? parsed : ({})
        store.error = Defaults.isObject(parsed) ? "" : "the config file is not a JSON object"
      } catch (e) {
        // Half written, or edited by hand with a typo: keep what is shown.
        store.error = "the config file is not valid JSON: " + e
      }
      store.fileExists = true
    }
  }

  Timer {
    id: reloadTimer
    interval: 120
    onTriggered: store.readNow()
  }

  // The folder watcher notices the file being written or replaced.
  FolderListModel {
    id: watcher
    folder: "file://" + store.dir
    nameFilters: [store.fileName]
    showDirs: false
    showDotAndDotDot: false
    onDataChanged: store.reload()
    onCountChanged: store.reload()
  }

  // A file that does not exist yet (or a folder that does not) cannot be watched, and a watcher can miss a file that a
  // link points to being replaced: look now and then.
  Timer {
    interval: store.fileExists ? 20000 : 5000
    running: true
    repeat: true
    onTriggered: store.readNow()
  }

  onPathChanged: reload()
  Component.onCompleted: readNow()
}
