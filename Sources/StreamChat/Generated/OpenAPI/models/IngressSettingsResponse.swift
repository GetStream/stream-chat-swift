//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class IngressSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var audioEncodingOptions: IngressAudioEncodingResponse?
    var enabled: Bool
    var videoEncodingOptions: [String: IngressVideoEncodingResponse]?

    init(audioEncodingOptions: IngressAudioEncodingResponse? = nil, enabled: Bool, videoEncodingOptions: [String: IngressVideoEncodingResponse]? = nil) {
        self.audioEncodingOptions = audioEncodingOptions
        self.enabled = enabled
        self.videoEncodingOptions = videoEncodingOptions
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case audioEncodingOptions = "audio_encoding_options"
        case enabled
        case videoEncodingOptions = "video_encoding_options"
    }

    static func == (lhs: IngressSettingsResponse, rhs: IngressSettingsResponse) -> Bool {
        lhs.audioEncodingOptions == rhs.audioEncodingOptions &&
            lhs.enabled == rhs.enabled &&
            lhs.videoEncodingOptions == rhs.videoEncodingOptions
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(audioEncodingOptions)
        hasher.combine(enabled)
        hasher.combine(videoEncodingOptions)
    }
}
