//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

// Defines an enumeration for audio player playback state
public enum AudioPlaybackState: Equatable {
    // Cases representing different playback states
    case notLoaded
    case loading
    case paused
    case playing
    case stopped

    // Equatable implementation for comparing two instances of
    // AudioPlayerPlaybackState
    public static func == (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        switch (lhs, rhs) {
        // Cases where both instances have the same case, return true
        case
            (.notLoaded, .notLoaded),
            (.loading, .loading),
            (.paused, .paused),
            (.playing, .playing),
            (.stopped, .stopped):
            return true

        // All other cases, return false
        default:
            return false
        }
    }
}
