//
//  AudioPlaybackContext_Mock.swift
//  StreamChatTestTools
//
//  Created by Ilias Pavlidakis on 15/3/23.
//  Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatUI

extension AudioPlaybackContext {

    public static func dummy(
        duration: TimeInterval = 0,
        currentTime: TimeInterval = 0,
        state: AudioPlaybackState = .notLoaded,
        rate: AudioPlaybackRate = .zero,
        isSeeking: Bool = false
    ) -> AudioPlaybackContext {
        .init(
            duration: duration,
            currentTime: currentTime,
            state: state,
            rate: rate,
            isSeeking: isSeeking
        )
    }
}
