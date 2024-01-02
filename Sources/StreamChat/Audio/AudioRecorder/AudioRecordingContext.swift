//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A struct that represents the current state of an audio recording session
public struct AudioRecordingContext: Hashable {
    /// The current state of the audio recording session
    public var state: AudioRecordingState

    /// The duration of the recorded audio track in seconds
    public var duration: TimeInterval

    /// The averagePower reported during the last sampling of the recorded audio track
    public var averagePower: Float

    /// A static property representing a default "initial" state for an audio recording context
    public static let initial = AudioRecordingContext(
        state: .stopped,
        duration: 0,
        averagePower: 0
    )
}
