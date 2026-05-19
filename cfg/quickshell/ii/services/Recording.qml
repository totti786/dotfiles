pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common

import Quickshell
import QtQuick

/**
 * Simple screen recording indicator with pause support.
 * Uses ~/.local/bin/recorder command.
 */
Singleton {
    id: root

    property bool isRecording: false
    property bool isPaused: false
    property int recordingDuration: 0
    property int recordingStartTime: 0
    property int pausedDuration: 0
    property int pauseStartTime: 0

    // Timer for updating duration display
    Timer {
        id: durationTimer
        interval: 1000 // Update every second
        running: root.isRecording && !root.isPaused
        repeat: true
        onTriggered: {
            const now = Math.floor(Date.now() / 1000)
            root.recordingDuration = now - root.recordingStartTime - root.pausedDuration
        }
    }

    function startRecording(fullscreen: bool) {
        if (isRecording) return

        const args = ["recorder"]
        args.push(fullscreen ? "--screen" : "--area")
        
        Quickshell.execDetached(args)
        
        // Set recording state
        isRecording = true
        isPaused = false
        recordingStartTime = Math.floor(Date.now() / 1000)
        recordingDuration = 0
        pausedDuration = 0
    }

    function stopRecording() {
        if (!isRecording) return

        Quickshell.execDetached(["recorder", "--stop"])
        isRecording = false
        isPaused = false
        recordingDuration = 0
        pausedDuration = 0
    }

    function togglePause() {
        if (!isRecording) return
        
        if (isPaused) {
            // Resume
            isPaused = false
            pausedDuration += Math.floor(Date.now() / 1000) - pauseStartTime
        } else {
            // Pause
            isPaused = true
            pauseStartTime = Math.floor(Date.now() / 1000)
        }
    }

    // Format duration as MM:SS
    function formatDuration(seconds: int): string {
        const mins = Math.floor(seconds / 60)
        const secs = seconds % 60
        return String(mins).padStart(2, '0') + ":" + String(secs).padStart(2, '0')
    }
}
