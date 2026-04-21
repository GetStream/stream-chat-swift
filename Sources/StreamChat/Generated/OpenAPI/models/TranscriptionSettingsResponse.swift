//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class TranscriptionSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var closedCaptionMode: String
    var language: String
    var mode: String
    var speechSegmentConfig: SpeechSegmentConfig?
    var translation: TranslationSettings?

    init(closedCaptionMode: String, language: String, mode: String, speechSegmentConfig: SpeechSegmentConfig? = nil, translation: TranslationSettings? = nil) {
        self.closedCaptionMode = closedCaptionMode
        self.language = language
        self.mode = mode
        self.speechSegmentConfig = speechSegmentConfig
        self.translation = translation
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case closedCaptionMode = "closed_caption_mode"
        case language
        case mode
        case speechSegmentConfig = "speech_segment_config"
        case translation
    }

    static func == (lhs: TranscriptionSettingsResponse, rhs: TranscriptionSettingsResponse) -> Bool {
        lhs.closedCaptionMode == rhs.closedCaptionMode &&
            lhs.language == rhs.language &&
            lhs.mode == rhs.mode &&
            lhs.speechSegmentConfig == rhs.speechSegmentConfig &&
            lhs.translation == rhs.translation
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(closedCaptionMode)
        hasher.combine(language)
        hasher.combine(mode)
        hasher.combine(speechSegmentConfig)
        hasher.combine(translation)
    }
}
