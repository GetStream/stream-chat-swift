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
        case channelId = "channel_cid"
        case userId = "user_id"
        case disabledUntil = "disabled_until"
        case removeDisable = "remove_disable"
    }
}

struct PushPreferencePayload: Decodable {
    let chatLevel: String
    let disabledUntil: Date?

    enum CodingKeys: String, CodingKey {
        case chatLevel = "chat_level"
        case disabledUntil = "disabled_until"
    }

    func asModel() -> UserPushPreference {
        .init(
            level: PushPreferenceLevel(rawValue: chatLevel),
            disabledUntil: disabledUntil
        )
    }

    func asModel(channelId: ChannelId) -> ChannelPushPreference {
        .init(
            channelId: channelId,
            level: PushPreferenceLevel(rawValue: chatLevel),
            disabledUntil: disabledUntil
        )
    }
}

struct PushPreferencePayloadResponse: Decodable {
    let userPreferences: [String: PushPreferencePayload?]
    let channelPreferences: [String: [String: PushPreferencePayload]]

    enum CodingKeys: String, CodingKey {
        case userPreferences = "user_preferences"
        case channelPreferences = "user_channel_preferences"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userPreferences = try container.decodeIfPresent([String: PushPreferencePayload?].self, forKey: .userPreferences) ?? [:]
        channelPreferences = try container.decodeIfPresent([String: [String: PushPreferencePayload]].self, forKey: .channelPreferences) ?? [:]
    }

    func asModel() -> PushPreferences {
        .init(
            userPreferences: userPreferences.values.compactMap { $0?.asModel() },
            channelPreferences: channelPreferences.flatMap { key, innerDict in
                innerDict.compactMap { key, value in
                    guard let channelId = try? ChannelId(cid: key) else {
                        return nil
                    }
                    return value.asModel(channelId: channelId)
                }
            }.reduce(into: [:]) { partialResult, preference in
                partialResult[preference.channelId] = preference
            }
        )
    }
}
