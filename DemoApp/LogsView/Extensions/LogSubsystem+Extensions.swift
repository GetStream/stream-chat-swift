//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat

extension LogSubsystem {
    var displayNames: [String] {
        var names: [String] = []
        if contains(.other) { names.append("Other") }
        if contains(.database) { names.append("Database") }
        if contains(.httpRequests) { names.append("HTTP") }
        if contains(.webSocket) { names.append("WebSocket") }
        if contains(.offlineSupport) { names.append("Offline") }
        if contains(.authentication) { names.append("Auth") }
        if contains(.audioPlayback) { names.append("Audio Playback") }
        if contains(.audioRecording) { names.append("Audio Recording") }
        return names
    }

    var primaryDisplayName: String {
        let names = displayNames
        return names.first ?? "Unknown"
    }
}
