import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

DialogListItem {
    id: root
    required property string vpnName
    required property string vpnType
    required property bool isConnected
    
    active: isConnected
    pointingHandCursor: true
    
    onClicked: {
        if (isConnected) {
            Quickshell.execDetached(["nmcli", "-t", "con", "down", "id", vpnName])
        } else {
            Quickshell.execDetached(["nmcli", "-t", "con", "up", "id", vpnName])
        }
    }
    
    contentItem: ColumnLayout {
        anchors {
            fill: parent
            topMargin: root.verticalPadding
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }
        spacing: 0
        
        RowLayout {
            spacing: 10
            
            MaterialSymbol {
                iconSize: Appearance.font.pixelSize.larger
                text: isConnected ? "shield_lock" : "shield"
                color: isConnected ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
            }
            
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                
                StyledText {
                    Layout.fillWidth: true
                    color: isConnected ? Appearance.colors.colOnSurface : Appearance.colors.colOnSurfaceVariant
                    elide: Text.ElideRight
                    text: root.vpnName
                    textFormat: Text.PlainText
                }
                
                StyledText {
                    visible: root.vpnType !== ""
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    text: root.vpnType
                    textFormat: Text.PlainText
                }
            }
            

        }
        
        Item {
            Layout.fillHeight: true
        }
    }
}
