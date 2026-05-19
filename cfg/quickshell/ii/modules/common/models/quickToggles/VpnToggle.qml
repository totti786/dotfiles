import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import Quickshell
import Quickshell.Io

QuickToggleModel {
    id: root
    name: Translation.tr("VPN")
    icon: "shield_lock"
    toggled: false
    available: false
    hasMenu: true

    // Track current VPN connection name
    property string activeVpnName: ""

    mainAction: () => {
        if (toggled && activeVpnName !== "") {
            // Disconnect current VPN
            Quickshell.execDetached(["nmcli", "-t", "con", "down", "id", activeVpnName])
            root.toggled = false
            root.activeVpnName = ""
        } else if (!toggled && availableVpnNames.length > 0) {
            // Connect to first available VPN
            Quickshell.execDetached(["nmcli", "-t", "con", "up", "id", availableVpnNames[0]])
            root.toggled = true
            root.activeVpnName = availableVpnNames[0]
        }
    }

    // Store available VPN connection names
    property list<string> availableVpnNames: []

    // Fetch available VPN connections (wireguard, openvpn, and generic vpn types)
    Process {
        id: fetchVpnList
        running: true
        command: ["bash", "-c", "nmcli -t -f NAME,TYPE con show | grep -iE ':(wireguard|openvpn|vpn)$' | cut -d: -f1"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    let lines = text.trim().split('\n').filter(line => line.length > 0)
                    availableVpnNames = lines
                    root.available = lines.length > 0
                } else {
                    availableVpnNames = []
                    root.available = false
                }
            }
        }
    }

    // Fetch active VPN connection state
    Process {
        id: fetchActiveState
        running: true
        command: ["bash", "-c", "nmcli -t -f NAME,TYPE,STATE con show | grep -iE ':(wireguard|openvpn|vpn):"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    let lines = text.trim().split('\n').filter(line => line.length > 0)
                    // Format: NAME:TYPE:STATE (e.g., "Romania:wireguard:activated")
                    for (let i = 0; i < lines.length; i++) {
                        let parts = lines[i].split(':')
                        if (parts.length >= 3 && parts[2] === "activated") {
                            root.toggled = true
                            root.activeVpnName = parts[0]
                            return
                        }
                    }
                    root.toggled = false
                    root.activeVpnName = ""
                } else {
                    root.toggled = false
                    root.activeVpnName = ""
                }
            }
        }
    }

    statusText: activeVpnName !== "" ? activeVpnName : (availableVpnNames.length > 0 ? availableVpnNames[0] : "")
    tooltipText: availableVpnNames.length > 0
        ? Translation.tr("%1 | Right-click for more options").arg(activeVpnName !== "" ? activeVpnName : availableVpnNames[0])
        : Translation.tr("No VPN configured")
}
