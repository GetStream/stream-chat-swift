//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A struct that represents the current state of an audio player
public struct AudioPlaybackContext: Equatable {
    public var assetLocation: URL?

    /// The duration of the audio track in seconds
    public var duration: TimeInterval

    /// The current playback time in seconds
    public var currentTime: TimeInterval

    /// The current playback state of the audio player
    public var state: AudioPlaybackState

    /// The current playback rate of the audio player
    public var rate: AudioPlaybackRate

    /// A boolean flag indicating whether the audio player is currently seeking to a new position in the track
    public var isSeeking: Bool

    /// A static property representing a default "not loaded" state for an audio player context
    public static let notLoaded = AudioPlaybackContext(
        assetLocation: nil,
        duration: 0,
        currentTime: 0,
        state: .notLoaded,
        rate: .zero,
        isSeeking: false
    )
}
