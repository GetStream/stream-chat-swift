//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

struct PushPreferenceRequestPayload: Encodable {
    let chatLevel: String?
    let channelId: String?
    let userId: String
    let disabledUntil: Date?
    let removeDisable: Bool?

    enum CodingKeys: String, CodingKey {
        case chatLevel = "chat_level"
        case channelId = "channel_id"
        case userId = "user_id"
        case disabledUntil = "disabled_until"
        case removeDisable = "remove_disable"
    }
}

struct UserPushPreferencePayloadResponse: Decodable {
    let userId: String
    let chatLevel: String
    let disabledUntil: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case chatLevel = "chat_level"
        case disabledUntil = "disabled_until"
    }

    func asModel() -> UserPushPreference {
        .init(
            level: PushPreferenceLevel(rawValue: chatLevel),
            disabledUntil: disabledUntil
        )
    }
}

struct ChannelPushPreferencePayloadResponse: Decodable {
    let channelId: ChannelId
    let chatLevel: String
    let disabledUntil: Date?

    enum CodingKeys: String, CodingKey {
        case channelId = "channel_id"
        case chatLevel = "chat_level"
        case disabledUntil = "disabled_until"
    }

    func asModel() -> ChannelPushPreference {
        .init(
            channelId: channelId,
            level: PushPreferenceLevel(rawValue: chatLevel),
            disabledUntil: disabledUntil
        )
    }
}

struct PushPreferencePayloadResponse: Decodable {
    let userPreferences: [UserPushPreferencePayloadResponse]
    let channelPreferences: [ChannelPushPreferencePayloadResponse]

    enum CodingKeys: String, CodingKey {
        case userPreferences = "user_preferences"
        case channelPreferences = "channel_preferences"
    }

    func asModel() -> PushPreferences {
        .init(
            userPreferences: userPreferences.map { $0.asModel() },
            channelPreferences: channelPreferences.map { $0.asModel() }
        )
    }
}
