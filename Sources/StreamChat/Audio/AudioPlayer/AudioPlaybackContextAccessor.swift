//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Provides thread-safe access to the value's storage
final class AudioPlaybackContextAccessor {
    /// The queue that thread-safe access to the value's storage
    private var accessQueue: DispatchQueue

    private var _value: AudioPlaybackContext
    var value: AudioPlaybackContext {
        get { readValue() }
        set { writeValue(newValue) }
    }

    init(
        _ initialValue: AudioPlaybackContext
    ) {
        _value = initialValue
        accessQueue = .init(
            label: "com.getstream.audio.playback.context.accessor)",
            qos: .userInteractive
        )
    }

    private func readValue() -> AudioPlaybackContext {
        accessQueue.sync { _value }
    }

    private func writeValue(_ newValue: AudioPlaybackContext) {
        accessQueue.async { [weak self] in
            self?._value = newValue
        }
    }
}
