import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // ---- config ----
    // Helper ships inside the package; resolve its path relative to this file
    // so the widget works on any machine (no hardcoded home path). It reads
    // the default profile (~/.copilot) unless install.sh was given a custom
    // COPILOT_HOME (see contents/code/copilot-usage.py).
    readonly property string scriptPath: Qt.resolvedUrl("../code/copilot-usage.py").toString().replace(/^file:\/\//, "")
    readonly property string cmd: "python3 '" + scriptPath + "'"
    readonly property int pollMs: 300000   // 5 min — quota moves slowly, no need to hammer it

    // ---- state ----
    property var quotas: []            // [{kind, label, unlimited, util, entitlement, remaining}]
    property var primary: null         // the premium_interactions row, or first available
    property double resetMs: 0
    property string plan: ""
    property string login: ""          // whichever GitHub login the profile's config.json reports
    property string copilotHome: ""    // resolved COPILOT_HOME, from the helper — reported on every run, even errors
    property string errorMsg: ""
    property double nowMs: 0           // ticks every 30s for live countdowns
    property double lastFetchMs: 0     // when the last successful fetch landed
    property bool busy: false          // a fetch is in flight
    property int fetchSeq: 0           // makes each run a distinct DataSource source

    Plasmoid.icon: "utilities-system-monitor"
    toolTipMainText: "Copilot Usage" + (root.login ? (" (" + root.login + ")") : "")
    toolTipSubText: root.primary
        ? ((root.primary.unlimited ? "Unlimited" : (Math.round(root.primary.util) + "%"))
           + " · resets " + remainStr(root.resetMs)
           + "\nMiddle-click to refresh")
        : (errorMsg !== "" ? statusText() : "No data")

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Refresh now"
            icon.name: "view-refresh"
            onTriggered: root.refresh()
        }
    ]

    // ---------- data fetch ----------
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
                    root.copilotHome = p.copilot_home ? p.copilot_home : root.copilotHome
                    // Only blank the data on genuine auth loss. Transient errors
                    // (rate limit, network blip) keep the last-known values so
                    // the widget degrades gracefully instead of flickering empty.
                    if (p.error === "no-token" || p.error === "http-401") {
                        root.quotas = []
                        root.primary = null
                    }
                    return
                }
                root.quotas = p.quotas ? p.quotas : []
                root.primary = null
                for (var i = 0; i < root.quotas.length; ++i) {
                    if (root.quotas[i].kind === "premium_interactions") { root.primary = root.quotas[i]; break }
                }
                if (!root.primary && root.quotas.length > 0) root.primary = root.quotas[0]
                root.resetMs = p.reset_ms ? p.reset_ms : 0
                root.plan = p.plan ? p.plan : ""
                root.login = p.login ? p.login : ""
                root.copilotHome = p.copilot_home ? p.copilot_home : root.copilotHome
                root.lastFetchMs = p.fetched_ms ? p.fetched_ms : new Date().getTime()
                root.errorMsg = ""
            } catch (e) {
                root.errorMsg = "parse"
            }
        }
    }

    // Force a fetch right now. The trailing shell comment gives every run a
    // distinct source name, so a manual refresh always re-executes instead of
    // being swallowed as a duplicate of the source already connected.
    //
    // The counter WRAPS, and must — see claude-usage-widget's CLAUDE.md for
    // why an unbounded counter here pins plasmashell's main thread at 100%
    // over time (Plasma5Support source names are append-only QMetaObject
    // properties; every connect/disconnect rebuilds over all of them).
    function refresh() {
        root.busy = true
        root.fetchSeq = (root.fetchSeq + 1) % 8
        root.nowMs = new Date().getTime()
        exec.connectSource(root.cmd + " # " + root.fetchSeq)
    }

    Timer { interval: root.pollMs; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.nowMs = new Date().getTime() }
    // Watchdog: the helper self-limits to a 10s HTTP timeout, so anything past
    // 20s means the run is gone — clear the spinner rather than wedge on it.
    Timer {
        interval: 20000; running: root.busy; repeat: false
        onTriggered: root.busy = false
    }

    // ---------- helpers ----------
    function remainStr(resetMs) {
        if (!resetMs) return "—"
        var ms = Math.max(0, resetMs - nowMs)
        var totalMin = Math.floor(ms / 60000)
        var d = Math.floor(totalMin / 1440)
        var h = Math.floor((totalMin % 1440) / 60)
        var m = totalMin % 60
        if (d > 0) return d + "d " + h + "h"
        if (h > 0) return h + "h" + (m < 10 ? "0" : "") + m + "m"
        return m + "m"
    }
    function resetAtStr(resetMs) {
        if (!resetMs) return ""
        return Qt.formatDateTime(new Date(resetMs), "ddd d MMM")
    }
    function agoStr(ms) {
        if (!ms) return "never"
        var mins = Math.floor(Math.max(0, nowMs - ms) / 60000)
        if (mins < 1) return "just now"
        if (mins < 60) return mins + "m ago"
        return Math.floor(mins / 60) + "h ago"
    }
    function utilColor(u) {
        if (u === undefined || u === null) return Kirigami.Theme.textColor
        if (u >= 90) return Kirigami.Theme.negativeTextColor
        if (u >= 70) return Kirigami.Theme.neutralTextColor
        return Kirigami.Theme.positiveTextColor
    }
    function statusText() {
        if (errorMsg === "no-token" || errorMsg === "http-401") return "Sign in to Copilot"
        if (errorMsg === "net" || errorMsg === "exec") return "Offline"
        return "Error"
    }

    // ---------- compact (in-panel): just text, % above, time below ----------
    compactRepresentation: MouseArea {
        id: compact
        Layout.minimumWidth: col.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: col.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.minimumHeight: col.implicitHeight
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) root.refresh()
            else root.expanded = !root.expanded
        }

        ColumnLayout {
            id: col
            anchors.centerIn: parent
            spacing: 0

            PlasmaComponents3.Label {   // premium-request % — headline
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                text: root.primary
                      ? (root.primary.unlimited ? "∞" : (Math.round(root.primary.util) + "%"))
                      : "—"
                color: root.primary && !root.primary.unlimited ? root.utilColor(root.primary.util) : Kirigami.Theme.disabledTextColor
                font.bold: true
                font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.1)
                font.features: { "tnum": 1 }
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 8
                horizontalAlignment: Text.AlignHCenter
            }
            PlasmaComponents3.Label {   // time until reset — below
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                text: root.primary ? root.remainStr(root.resetMs)
                                    : (root.errorMsg !== "" ? "!" : "…")
                opacity: root.busy ? 0.45 : 0.8
                font.pixelSize: Math.round(Kirigami.Theme.smallFont.pixelSize)
                font.features: { "tnum": 1 }
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 7
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // ---------- full (popup) ----------
    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
        Layout.minimumHeight: Kirigami.Units.gridUnit * 14

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            // ---- header: title + refresh ----
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Heading { level: 3; text: "Copilot Usage" }
                PlasmaComponents3.Label {
                    text: [root.login, root.plan].filter(s => !!s).join(" · ")
                    visible: text.length > 0
                    opacity: 0.55
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
                Item { Layout.fillWidth: true }

                PlasmaComponents3.Label {
                    text: root.busy ? "Refreshing…" : ("Updated " + root.agoStr(root.lastFetchMs))
                    opacity: 0.6
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
                PlasmaComponents3.BusyIndicator {
                    running: root.busy
                    visible: root.busy
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                }
                PlasmaComponents3.ToolButton {
                    icon.name: "view-refresh"
                    display: PlasmaComponents3.AbstractButton.IconOnly
                    text: "Refresh now"
                    enabled: !root.busy
                    onClicked: root.refresh()
                    PlasmaComponents3.ToolTip.text: "Fetch usage now"
                    PlasmaComponents3.ToolTip.visible: hovered
                    PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }

            // ---- reset date (shared by all quota types) ----
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                visible: root.quotas.length > 0 && root.resetMs > 0
                text: "Resets in " + root.remainStr(root.resetMs) + " · " + root.resetAtStr(root.resetMs)
                opacity: 0.7
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }

            Kirigami.Separator { Layout.fillWidth: true; visible: root.quotas.length > 0 }

            // ---- quota rows ----
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.quotas.length > 0
                spacing: Kirigami.Units.largeSpacing

                Repeater {
                    model: root.quotas
                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            PlasmaComponents3.Label { text: modelData.label; opacity: 0.8 }
                            Item { Layout.fillWidth: true }
                            PlasmaComponents3.Label {
                                text: modelData.unlimited ? "Unlimited"
                                      : ((modelData.util !== null && modelData.util !== undefined)
                                         ? (Math.round(modelData.util) + "%") : "—")
                                font.bold: true
                                color: modelData.unlimited ? Kirigami.Theme.positiveTextColor : root.utilColor(modelData.util)
                            }
                        }
                        PlasmaComponents3.ProgressBar {
                            Layout.fillWidth: true; from: 0; to: 100
                            visible: !modelData.unlimited
                            value: modelData.util ? modelData.util : 0
                        }
                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            visible: !modelData.unlimited && modelData.entitlement
                            text: modelData.entitlement
                                  ? ((modelData.remaining !== null && modelData.remaining !== undefined ? modelData.remaining : "?")
                                     + " / " + modelData.entitlement + " remaining")
                                  : ""
                            opacity: 0.7
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }
                    }
                }
            }

            // ---- error / signed-out state ----
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.quotas.length === 0
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                opacity: 0.7
                text: root.errorMsg === "no-token" || root.errorMsg === "http-401"
                      ? ("Not signed in.\nRun: " + (root.copilotHome ? ("COPILOT_HOME=" + root.copilotHome + " copilot") : "copilot"))
                      : (root.errorMsg !== "" ? ("Couldn't reach the usage API (" + root.errorMsg + ").")
                                              : "Loading…")
            }

            Item { Layout.fillHeight: true }
        }
    }
}
