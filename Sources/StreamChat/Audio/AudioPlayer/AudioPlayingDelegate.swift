//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object that the audioPlayer can communicate updates regarding its context
public protocol AudioPlayingDelegate: AnyObject {
    /// The audioPlayer will call this one to inform its delegate that the the playback's context has
    /// been updated.
    func audioPlayer(
        _ audioPlayer: AudioPlaying,
        didUpdateContext context: AudioPlaybackContext
    )
}
