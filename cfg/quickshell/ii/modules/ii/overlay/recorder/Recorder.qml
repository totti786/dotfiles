pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    minimumWidth: 280
    minimumHeight: Recording.isRecording ? 100 : 130

    contentItem: OverlayBackground {
        id: contentItem
        radius: root.contentRadius
        property real padding: 8
        ColumnLayout {
            id: contentColumn
            anchors.centerIn: parent
            spacing: 10

            // Recording status (when active)
            RowLayout {
                visible: Recording.isRecording
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: Appearance.colors.colError

                    SequentialAnimation on opacity {
                        running: Recording.isRecording
                        loops: Animation.Infinite
                        NumberAnimation { from: 1; to: 0.3; duration: 800 }
                        NumberAnimation { from: 0.3; to: 1; duration: 800 }
                    }
                }

                StyledText {
                    text: Recording.formatDuration(Recording.recordingDuration)
                    font.pixelSize: 28
                    font.weight: Font.Bold
                    font.family: Appearance.font.family.numbers
                    color: Appearance.colors.colError
                }

                RippleButton {
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: 20
                    colBackground: Appearance.colors.colError
                    colBackgroundHover: ColorUtils.mix(Appearance.colors.colError, "white", 0.2)
                    onClicked: {
                        Recording.stopRecording()
                        GlobalStates.overlayOpen = false
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "stop"
                        color: "white"
                        iconSize: 24
                    }
                }
            }

            // Action buttons (when not recording)
            Row {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                spacing: 10
                visible: !Recording.isRecording

                BigRecorderButton {
                    materialSymbol: "screenshot_region"
                    name: "Screenshot region"
                    onClicked: {
                        GlobalStates.overlayOpen = false;
                        Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "screenshot"])
                    }
                }

                BigRecorderButton {
                    materialSymbol: "photo_camera"
                    name: "Screenshot"
                    onClicked: {
                        GlobalStates.overlayOpen = false;
                        Quickshell.execDetached(["bash", "-c", "grim - | wl-copy"])
                    }
                }

                BigRecorderButton {
                    materialSymbol: "screen_record"
                    name: "Record area"
                    onClicked: {
                        GlobalStates.overlayOpen = false;
                        Recording.startRecording(false)
                    }
                }

                BigRecorderButton {
                    materialSymbol: "capture"
                    name: "Record screen"
                    onClicked: {
                        GlobalStates.overlayOpen = false;
                        Recording.startRecording(true)
                    }
                }
            }

            // Open recordings folder button
            RippleButton {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.fillWidth: false
                buttonRadius: height / 2
                colBackground: Appearance.colors.colLayer3
                colBackgroundHover: Appearance.colors.colLayer3Hover
                colRipple: Appearance.colors.colLayer3Active
                onClicked: {
                    GlobalStates.overlayOpen = false;
                    Qt.openUrlExternally(`file://${Config.options.screenRecord.savePath}`)
                }
                contentItem: Row {
                    anchors.centerIn: parent
                    spacing: 6
                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "folder_open"
                        iconSize: 20
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("Open recordings")
                    }
                }
            }
        }
    }

    component BigRecorderButton: RippleButton {
        id: bigButton
        required property string materialSymbol
        required property string name
        implicitHeight: 66
        implicitWidth: 66
        buttonRadius: height / 2

        colBackground: Appearance.colors.colLayer3
        colBackgroundHover: Appearance.colors.colLayer3Hover
        colRipple: Appearance.colors.colLayer3Active

        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: bigButton.materialSymbol
            iconSize: 28
        }

        StyledToolTip {
            text: bigButton.name
        }
    }
}
