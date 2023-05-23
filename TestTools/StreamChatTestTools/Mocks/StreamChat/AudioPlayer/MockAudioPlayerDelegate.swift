//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public final class MockAudioPlayerDelegate: AudioPlayingDelegate {
    public private(set) var didUpdateContextWasCalledWithPlayer: AudioPlaying?
    public private(set) var didUpdateContextWasCalledWithContext: AudioPlaybackContext?

    public init() {}

    public func audioPlayer(
        _ audioPlayer: AudioPlaying,
        didUpdateContext context: AudioPlaybackContext
    ) {
        didUpdateContextWasCalledWithPlayer = audioPlayer
        didUpdateContextWasCalledWithContext = context
    }
}
