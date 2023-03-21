//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatUI

public final class MockAudioPlayerDelegate: AudioPlayingDelegate {
    public private(set) var didUpdateContextWasCalled: (player: AudioPlaying, context: AudioPlaybackContext)?

    public init() {}

    public func audioPlayer(
        _ audioPlayer: AudioPlaying,
        didUpdateContext context: AudioPlaybackContext
    ) {
        didUpdateContextWasCalled = (audioPlayer, context)
    }
}
