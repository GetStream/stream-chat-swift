//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Defines a struct named AudioRecordingState that is being used to describe the state of a recording
/// session.
public struct AudioRecordingState: Hashable {
    var rawValue: String

    /// Defines a static constant property called recording of type AudioRecordingState with a raw value
    /// of "recording". It's being used when a recording sessions is actively recording.
    public static let recording = AudioRecordingState(rawValue: "recording")

    /// Defines a static constant property called paused of type AudioRecordingState with a raw value
    /// of "paused". It's being used when a recording sessions has been paused during recording.
    public static let paused = AudioRecordingState(rawValue: "paused")

    /// Defines a static constant property called stopped of type AudioRecordingState with a raw value
    /// of "stopped". It's being used when a recording sessions has stopped recording.
    public static let stopped = AudioRecordingState(rawValue: "stopped")
}
