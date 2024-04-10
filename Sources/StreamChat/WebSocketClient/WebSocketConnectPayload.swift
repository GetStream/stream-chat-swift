//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

class WebSocketConnectPayload: Encodable {
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userDetails = "user_details"
        case serverDeterminesConnectionId = "server_determines_connection_id"
    }

    let userId: UserId
    let userDetails: UserWebSocketPayload
    let serverDeterminesConnectionId: Bool

    init(userInfo: UserInfo) {
        userId = userInfo.id
        userDetails = UserWebSocketPayload(userInfo: userInfo)
        serverDeterminesConnectionId = true
    }
}

struct UserWebSocketPayload: Encodable {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case name
        case isInvisible = "invisible"
        case imageURL = "image"
        case language
        case privateSettings = "private_settings"
    }

    let id: String
    let name: String?
    let imageURL: URL?
    let isInvisible: Bool?
    let language: String?
    let privateSettings: UserPrivateSettingsPayload?
    let extraData: [String: RawJSON]

    init(userInfo: UserInfo) {
        id = userInfo.id
        name = userInfo.name
        imageURL = userInfo.imageURL
        isInvisible = userInfo.isInvisible
        language = userInfo.language?.languageCode
        privateSettings = userInfo.privateSettings.map { .init(settings: $0) }
        extraData = userInfo.extraData
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(isInvisible, forKey: .isInvisible)
        try container.encodeIfPresent(language, forKey: .language)
        try container.encodeIfPresent(privateSettings, forKey: .privateSettings)
        try extraData.encode(to: encoder)
    }
}

struct UserPrivateSettingsPayload: Encodable {
    enum CodingKeys: String, CodingKey {
        case typingIndicators
        case readReceipts
    }

    let typingIndicators: TypingIndicatorPrivateSettingsPayload?
    let readReceipts: ReadReceiptsPrivateSettingsPayload?

    init(settings: UserPrivateSettings) {
        typingIndicators = settings.typingIndicators.map { .init(enabled: $0.enabled) }
        readReceipts = settings.readReceipts.map { .init(enabled: $0.enabled) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(typingIndicators, forKey: .typingIndicators)
        try container.encodeIfPresent(readReceipts, forKey: .readReceipts)
    }
}

struct TypingIndicatorPrivateSettingsPayload: Encodable {
    var enabled: Bool
}

struct ReadReceiptsPrivateSettingsPayload: Encodable {
    var enabled: Bool
}
