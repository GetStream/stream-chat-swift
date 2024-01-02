//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Provides thread-safe access to the value's storage
final class AudioRecordingContextAccessor {
    /// The queue that thread-safe access to the value's storage
    private var accessQueue: DispatchQueue

    private var _value: AudioRecordingContext
    var value: AudioRecordingContext {
        get { readValue() }
        set { writeValue(newValue) }
    }

    init(
        _ initialValue: AudioRecordingContext
    ) {
        _value = initialValue
        accessQueue = .init(
            label: "com.getstream.audio.recording.context.accessor)",
            qos: .userInteractive
        )
    }

    private func readValue() -> AudioRecordingContext {
        accessQueue.sync { _value }
    }

    private func writeValue(_ newValue: AudioRecordingContext) {
        accessQueue.async { [weak self] in
            self?._value = newValue
        }
    }
}
