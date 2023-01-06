//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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
    }

    let id: String
    let name: String?
    let imageURL: URL?
    let isInvisible: Bool
    let extraData: [String: RawJSON]

    init(userInfo: UserInfo) {
        id = userInfo.id
        name = userInfo.name
        imageURL = userInfo.imageURL
        isInvisible = userInfo.isInvisible
        extraData = userInfo.extraData
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(isInvisible, forKey: .isInvisible)
        try extraData.encode(to: encoder)
    }
}
