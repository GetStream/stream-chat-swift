//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Defines a struct that describes the audio playback rate with a raw value of Float
public struct AudioPlaybackRate: Comparable, Equatable {
    public let rawValue: Float

    public init(rawValue: Float) {
        self.rawValue = rawValue
    }

    public static func < (
        lhs: AudioPlaybackRate,
        rhs: AudioPlaybackRate
    ) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// SDK available playback rates
    public static let zero = AudioPlaybackRate(rawValue: 0)
    public static let half = AudioPlaybackRate(rawValue: 0.5)
    public static let normal = AudioPlaybackRate(rawValue: 1)
    public static let double = AudioPlaybackRate(rawValue: 2)
}
