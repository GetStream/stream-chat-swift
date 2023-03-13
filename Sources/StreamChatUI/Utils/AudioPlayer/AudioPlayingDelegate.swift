//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object that the audioPlayer can communicate updates regarding its context
public protocol AudioPlayingDelegate: AnyObject {
    func audioPlayer(
        _ audioPlayer: AudioPlaying,
        didUpdateContext context: AudioPlaybackContext
    )
}
