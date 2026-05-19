import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

WindowDialog {
    id: root
    backgroundHeight: 400
    
    property list<string> vpnNames: []
    property list<string> vpnTypes: []
    property list<bool> vpnConnected: []
    property string activeVpnName: ""
    
    function refreshVpnList() {
        fetchVpnList.running = true
        fetchActiveState.running = true
    }
    
    WindowDialogTitle {
        text: Translation.tr("VPN")
    }
    
    WindowDialogSeparator {}
    
    Timer {
        id: refreshTimer
        interval: 2000
        repeat: true
        running: root.visible
        onTriggered: refreshVpnList()
    }
    
    Process {
        id: fetchVpnList
        running: false
        command: ["bash", "-c", "nmcli -t -f NAME,TYPE con show | grep -iE ':(wireguard|openvpn|vpn)$'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    let lines = text.trim().split('\n').filter(line => line.length > 0)
                    let names = []
                    let types = []
                    for (let i = 0; i < lines.length; i++) {
                        let parts = lines[i].split(':')
                        if (parts.length >= 2) {
                            names.push(parts[0])
                            types.push(parts[1])
                        }
                    }
                    root.vpnNames = names
                    root.vpnTypes = types
                } else {
                    root.vpnNames = []
                    root.vpnTypes = []
                }
            }
        }
    }
    
    Process {
        id: fetchActiveState
        running: false
        command: ["bash", "-c", "nmcli -t -f NAME,STATE con show | grep ':activated$' | cut -d: -f1"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.activeVpnName = text.trim()
                let connected = []
                for (let i = 0; i < root.vpnNames.length; i++) {
                    connected.push(root.vpnNames[i] === root.activeVpnName)
                }
                root.vpnConnected = connected
            }
        }
    }
    
    StyledListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.topMargin: -15
        Layout.bottomMargin: -16
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large

        clip: true
        spacing: 0
        animateAppearance: false

        model: ScriptModel {
            values: root.vpnNames
        }
        delegate: VpnConnectionItem {
            required property string modelData
            vpnName: modelData
            vpnType: root.vpnTypes[index] || ""
            isConnected: root.vpnConnected[index] || false
            anchors {
                left: parent?.left
                right: parent?.right
            }
        }
    }
    
    WindowDialogSeparator {}
    WindowDialogButtonRow {
        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
    
    Component.onCompleted: refreshVpnList()
}
