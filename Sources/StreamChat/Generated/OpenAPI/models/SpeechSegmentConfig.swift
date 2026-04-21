//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SpeechSegmentConfig: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var maxSpeechCaptionMs: Int?
    var silenceDurationMs: Int?

    init(maxSpeechCaptionMs: Int? = nil, silenceDurationMs: Int? = nil) {
        self.maxSpeechCaptionMs = maxSpeechCaptionMs
        self.silenceDurationMs = silenceDurationMs
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case maxSpeechCaptionMs = "max_speech_caption_ms"
        case silenceDurationMs = "silence_duration_ms"
    }

    static func == (lhs: SpeechSegmentConfig, rhs: SpeechSegmentConfig) -> Bool {
        lhs.maxSpeechCaptionMs == rhs.maxSpeechCaptionMs &&
            lhs.silenceDurationMs == rhs.silenceDurationMs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(maxSpeechCaptionMs)
        hasher.combine(silenceDurationMs)
    }
}
