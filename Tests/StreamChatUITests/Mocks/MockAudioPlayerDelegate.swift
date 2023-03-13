//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatUI

final class MockAudioPlayerDelegate: AudioPlayingDelegate {
    private(set) var didUpdateContextWasCalled: (player: AudioPlaying, context: AudioPlaybackContext)?

    func audioPlayer(
        _ audioPlayer: AudioPlaying,
        didUpdateContext context: AudioPlaybackContext
    ) {
        didUpdateContextWasCalled = (audioPlayer, context)
    }
}
