//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// Provides easy setters/getters for the `VoiceRecording` feature required `extraData` fields.
extension Dictionary where Key == String, Value == RawJSON {
    private enum VoiceRecordingKey: String { case duration, waveform }

    var duration: TimeInterval? {
        get { self[VoiceRecordingKey.duration.rawValue]?.numberValue }

        set {
            self[VoiceRecordingKey.duration.rawValue] = newValue
                .map { .number(Double($0)) }
        }
    }

    var waveform: [Float]? {
        get {
            self[VoiceRecordingKey.waveform.rawValue]?
                .arrayValue
                .map { array in
                    array.compactMap { $0.numberValue.map(Float.init) }
                }
        }

        set {
            self[VoiceRecordingKey.waveform.rawValue] = newValue.map { array in
                .array(array.map { RawJSON.number(Double($0)) })
            }
        }
    }
}
