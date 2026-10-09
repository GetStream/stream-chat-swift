//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public extension LogEntry.Subsystem {
    /// Logs of the offline support.
    static let offlineSupport = Self(rawValue: "offlineSupport")
    /// Logs of authentication.
    static let authentication = Self(rawValue: "authentication")
    /// Logs of audio playback.
    static let audioPlayback = Self(rawValue: "audio-playback")
    /// Logs of audio recording.
    static let audioRecording = Self(rawValue: "audio-recording")

    /// Creates the viewer subsystem for a StreamCore subsystem.
    ///
    /// A single subsystem uses the same name the logger already reports. Any other value uses that value's description.
    init(_ subsystem: LogSubsystem) {
        self.init(rawValue: subsystem.description)
    }
}
