import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

// Claude usage: the session (5 h) and weekly limits, each as a percentage with its reset below, side by side in the
// panel. Which ones show and how the reset reads (time left or clock time) is set in the widget's settings. Data from
// contents/code/claude-usage.py, the endpoint behind Claude Code's /usage.
PlasmoidItem {
    id: root

    readonly property string scriptPath: Qt.resolvedUrl("../code/claude-usage.py").toString().replace(/^file:\/\//, "")
    readonly property string cmd: "python3 '" + scriptPath + "'"

    // ---- state ----
    property var session: null         // {util, resets_ms}
    property var weekly: null
    property var limits: []            // per-model weekly caps: [{label, util, resets_ms}]
    property string errorMsg: ""
    property double nowMs: new Date().getTime()
    property double lastFetchMs: 0
    property bool busy: false
    // Distinct source names for the executable engine. Must wrap: Plasma5Support keeps every source name it ever saw,
    // and an ever-growing set slows plasmashell down over time.
    property int fetchSeq: 0

    readonly property var shown: {
        var out = []
        if (Plasmoid.configuration.showSession) out.push({ name: "Session", data: root.session, weekly: false })
        if (Plasmoid.configuration.showWeekly) out.push({ name: "Weekly", data: root.weekly, weekly: true })
        return out
    }

    Plasmoid.icon: "utilities-system-monitor"
    toolTipMainText: "Claude Usage"
    toolTipSubText: errorMsg !== "" && !session ? statusText()
        : ("Session " + pct(session) + ", resets " + resetText(session, false, 0)
           + "\nWeekly " + pct(weekly) + ", resets " + resetText(weekly, true, 0) + "\nMiddle-click to refresh")

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Refresh now"
            icon.name: "view-refresh"
            onTriggered: root.refresh()
        }
    ]

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
            root.busy = false
            if (data["exit code"] !== 0) { root.errorMsg = "exec"; return }
            try {
                var p = JSON.parse(data["stdout"])
                if (p.error) {
                    root.errorMsg = p.error
                    // Keep the last values through rate limits and network blips; drop them when signed out.
                    if (p.error === "no-token" || p.error === "http-401") {
                        root.session = null
                        root.weekly = null
                        root.limits = []
                    }
                    return
                }
                root.session = p.session
                root.weekly = p.weekly
                root.limits = p.limits || []
                root.lastFetchMs = p.fetched_ms || new Date().getTime()
                root.errorMsg = ""
            } catch (e) {
                root.errorMsg = "parse"
            }
        }
    }

    function refresh() {
        root.busy = true
        root.fetchSeq = (root.fetchSeq + 1) % 8
        root.nowMs = new Date().getTime()
        exec.connectSource(root.cmd + " # " + root.fetchSeq)
    }

    Timer {
        interval: Math.max(1, Plasmoid.configuration.pollMinutes) * 60000
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.refresh()
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.nowMs = new Date().getTime() }
    Timer { interval: 20000; running: root.busy; onTriggered: root.busy = false }

    // ---------- helpers ----------
    function pct(d) {
        return d && d.util !== null && d.util !== undefined ? Math.round(d.util) + "%" : "—"
    }
    function leftStr(ms) {
        var totalMin = Math.floor(Math.max(0, ms - nowMs) / 60000)
        var d = Math.floor(totalMin / 1440), h = Math.floor((totalMin % 1440) / 60), m = totalMin % 60
        if (d > 0) return d + "d " + h + "h"
        if (h > 0) return h + "h" + (m < 10 ? "0" : "") + m + "m"
        return m + "m"
    }
    // style 0: time left, 1: clock time ("14:30", the weekday too when it is not today)
    function resetText(d, weekly, style) {
        if (!d || !d.resets_ms) return "—"
        if (style === 0) return leftStr(d.resets_ms)
        var at = new Date(d.resets_ms)
        var today = new Date(nowMs).toDateString() === at.toDateString()
        return Qt.formatDateTime(at, (weekly || !today) ? "ddd HH:mm" : "HH:mm")
    }
    function utilColor(d) {
        if (!d || d.util === null || d.util === undefined) return Kirigami.Theme.disabledTextColor
        if (d.util >= 90) return Kirigami.Theme.negativeTextColor
        if (d.util >= 70) return Kirigami.Theme.neutralTextColor
        return Kirigami.Theme.positiveTextColor
    }
    function agoStr(ms) {
        if (!ms) return "never"
        var mins = Math.floor(Math.max(0, nowMs - ms) / 60000)
        return mins < 1 ? "just now" : (mins < 60 ? mins + "m ago" : Math.floor(mins / 60) + "h ago")
    }
    function statusText() {
        if (errorMsg === "no-token" || errorMsg === "http-401") return "Not signed in: run claude"
        if (errorMsg === "http-429") return "Rate limited, retrying"
        if (errorMsg === "net" || errorMsg === "exec") return "Offline"
        return "Error (" + errorMsg + ")"
    }

    // ---------- in the panel: a column per limit, % above, reset below ----------
    compactRepresentation: MouseArea {
        Layout.minimumWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        Layout.minimumHeight: row.implicitHeight
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) root.refresh()
            else root.expanded = !root.expanded
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing

            Repeater {
                model: root.shown
                delegate: ColumnLayout {
                    required property var modelData
                    spacing: 0

                    PlasmaComponents3.Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.pct(modelData.data)
                        color: root.utilColor(modelData.data)
                        font.bold: true
                        font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.1)
                        font.features: { "tnum": 1 }
                    }
                    PlasmaComponents3.Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.resetText(modelData.data, modelData.weekly, Plasmoid.configuration.resetStyle)
                        opacity: root.busy ? 0.45 : 0.8
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        font.features: { "tnum": 1 }
                    }
                }
            }
            PlasmaComponents3.Label {
                visible: root.shown.length === 0
                text: "Claude"
            }
        }
    }

    // ---------- popup ----------
    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
        Layout.minimumHeight: Kirigami.Units.gridUnit * 12

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Layout.fillWidth: true
                Kirigami.Heading { level: 3; text: "Claude Usage" }
                Item { Layout.fillWidth: true }
                PlasmaComponents3.Label {
                    text: root.busy ? "Refreshing…" : ("Updated " + root.agoStr(root.lastFetchMs))
                    opacity: 0.6
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
                PlasmaComponents3.ToolButton {
                    icon.name: "view-refresh"
                    display: PlasmaComponents3.AbstractButton.IconOnly
                    text: "Refresh now"
                    enabled: !root.busy
                    onClicked: root.refresh()
                }
            }

            Kirigami.Separator { Layout.fillWidth: true }

            Repeater {
                model: {
                    var rows = [{ label: "Session (5 hours)", data: root.session, weekly: false },
                                { label: "Weekly, all models", data: root.weekly, weekly: true }]
                    for (var i = 0; i < root.limits.length; ++i) {
                        rows.push({ label: "Weekly, " + root.limits[i].label, data: root.limits[i], weekly: true })
                    }
                    return rows
                }
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 2
                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents3.Label { text: modelData.label; opacity: 0.8 }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents3.Label {
                            text: root.pct(modelData.data)
                            font.bold: true
                            color: root.utilColor(modelData.data)
                        }
                    }
                    PlasmaComponents3.ProgressBar {
                        Layout.fillWidth: true
                        from: 0; to: 100
                        value: modelData.data && modelData.data.util ? modelData.data.util : 0
                    }
                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: "Resets in " + root.resetText(modelData.data, modelData.weekly, 0)
                              + " · " + root.resetText(modelData.data, true, 1)
                        opacity: 0.7
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }
                }
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                visible: root.errorMsg !== ""
                wrapMode: Text.WordWrap
                opacity: 0.7
                text: root.statusText()
            }

            Item { Layout.fillHeight: true }
        }
    }
}
