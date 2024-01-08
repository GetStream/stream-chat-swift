//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Defines an struct which describes an audio player's playback state
public struct AudioPlaybackState: Equatable, CustomStringConvertible {
    /// The name that describes the state
    public let name: String

    public var description: String { "\(type(of: self)):\(name)" }

    /// Cases representing different playback states
    public static let notLoaded = AudioPlaybackState(name: "notLoaded")
    public static let loading = AudioPlaybackState(name: "loading")
    public static let paused = AudioPlaybackState(name: "paused")
    public static let playing = AudioPlaybackState(name: "playing")
    public static let stopped = AudioPlaybackState(name: "stopped")
}
