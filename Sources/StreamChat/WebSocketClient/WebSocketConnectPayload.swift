//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

class WebSocketConnectPayload: Encodable {
    private enum CodingKeys: String, CodingKey {
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
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case name
        case imageURL = "image_url"
    }

    let id: String
    let name: String?
    let imageURL: URL?
    let extraData: CustomData

    init(userInfo: UserInfo) {
        id = userInfo.id
        name = userInfo.name
        imageURL = userInfo.imageURL
        extraData = userInfo.extraData
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(id, forKey: .id)
        try container.encode(id, forKey: .name)
        try container.encode(id, forKey: .imageURL)

        try extraData.encode(to: encoder)
    }
}
