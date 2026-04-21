//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class RuleBuilderAction: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum RuleBuilderActionType: String, Sendable, Codable, CaseIterable {
        case banUser = "ban_user"
        case blockContent = "block_content"
        case blur
        case bounceContent = "bounce_content"
        case bounceFlagContent = "bounce_flag_content"
        case bounceRemoveContent = "bounce_remove_content"
        case callBlur = "call_blur"
        case callWarning = "call_warning"
        case endCall = "end_call"
        case flagContent = "flag_content"
        case flagUser = "flag_user"
        case kickUser = "kick_user"
        case muteAudio = "mute_audio"
        case muteVideo = "mute_video"
        case shadowContent = "shadow_content"
        case warning
        case webhookOnly = "webhook_only"
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

    var banOptions: BanOptions?
    var callOptions: CallActionOptions?
    var flagUserOptions: FlagUserOptions?
    var skipInbox: Bool?
    var type: RuleBuilderActionType?

    init(banOptions: BanOptions? = nil, callOptions: CallActionOptions? = nil, flagUserOptions: FlagUserOptions? = nil, skipInbox: Bool? = nil) {
        self.banOptions = banOptions
        self.callOptions = callOptions
        self.flagUserOptions = flagUserOptions
        self.skipInbox = skipInbox
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case banOptions = "ban_options"
        case callOptions = "call_options"
        case flagUserOptions = "flag_user_options"
        case skipInbox = "skip_inbox"
        case type
    }

    static func == (lhs: RuleBuilderAction, rhs: RuleBuilderAction) -> Bool {
        lhs.banOptions == rhs.banOptions &&
            lhs.callOptions == rhs.callOptions &&
            lhs.flagUserOptions == rhs.flagUserOptions &&
            lhs.skipInbox == rhs.skipInbox &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(banOptions)
        hasher.combine(callOptions)
        hasher.combine(flagUserOptions)
        hasher.combine(skipInbox)
        hasher.combine(type)
    }
}
