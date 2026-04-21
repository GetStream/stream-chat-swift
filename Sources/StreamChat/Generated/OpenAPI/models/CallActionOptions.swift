//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CallActionOptions: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var duration: Int?
    var flagReason: String?
    var kickReason: String?
    var muteAudio: Bool?
    var muteVideo: Bool?
    var reason: String?
    var warningText: String?

    init(duration: Int? = nil, flagReason: String? = nil, kickReason: String? = nil, muteAudio: Bool? = nil, muteVideo: Bool? = nil, reason: String? = nil, warningText: String? = nil) {
        self.duration = duration
        self.flagReason = flagReason
        self.kickReason = kickReason
        self.muteAudio = muteAudio
        self.muteVideo = muteVideo
        self.reason = reason
        self.warningText = warningText
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case flagReason = "flag_reason"
        case kickReason = "kick_reason"
        case muteAudio = "mute_audio"
        case muteVideo = "mute_video"
        case reason
        case warningText = "warning_text"
    }

    static func == (lhs: CallActionOptions, rhs: CallActionOptions) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.flagReason == rhs.flagReason &&
            lhs.kickReason == rhs.kickReason &&
            lhs.muteAudio == rhs.muteAudio &&
            lhs.muteVideo == rhs.muteVideo &&
            lhs.reason == rhs.reason &&
            lhs.warningText == rhs.warningText
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(flagReason)
        hasher.combine(kickReason)
        hasher.combine(muteAudio)
        hasher.combine(muteVideo)
        hasher.combine(reason)
        hasher.combine(warningText)
    }
}
