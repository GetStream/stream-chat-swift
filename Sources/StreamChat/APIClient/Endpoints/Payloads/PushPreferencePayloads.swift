//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

struct PushPreferenceRequestPayload: Encodable {
    let chatLevel: String?
    let channelId: String?
    let disabledUntil: Date?
    let removeDisable: Bool?

    enum CodingKeys: String, CodingKey {
        case chatLevel = "chat_level"
        case channelId = "channel_cid"
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

    func asModel() -> PushPreference {
        .init(
            level: PushPreferenceLevel(rawValue: chatLevel),
            disabledUntil: disabledUntil
        )
    }
}

struct PushPreferencesPayloadResponse: Decodable {
    let userPreferences: UserPushPreferencesPayload
    let channelPreferences: ChannelPushPreferencesPayload

    enum CodingKeys: String, CodingKey {
        case userPreferences = "user_preferences"
        case channelPreferences = "user_channel_preferences"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userPreferences = try container.decodeIfPresent(UserPushPreferencesPayload.self, forKey: .userPreferences) ?? [:]
        channelPreferences = try container.decodeIfPresent(ChannelPushPreferencesPayload.self, forKey: .channelPreferences) ?? [:]
    }
}

typealias UserPushPreferencesPayload = [String: PushPreferencePayload?]
typealias ChannelPushPreferencesPayload = [String: [String: PushPreferencePayload]]

extension UserPushPreferencesPayload {
    func asModel() -> [PushPreference] {
        values.compactMap { $0?.asModel() }
    }
}

extension ChannelPushPreferencesPayload {
    func asModel() -> [ChannelId: PushPreference] {
        .init(uniqueKeysWithValues: values
            .flatMap { $0 }
            .compactMap { key, value in
                guard let channelId = try? ChannelId(cid: key) else { return nil }
                return (channelId, value.asModel())
            }
        )
    }
}
