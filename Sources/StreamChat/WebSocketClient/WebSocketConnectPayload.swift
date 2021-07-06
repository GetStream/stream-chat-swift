//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

struct WebSocketConnectPayload<ExtraData: ExtraDataTypes>: Encodable {
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userDetails = "user_details"
        case serverDeterminesConnectionId = "server_determines_connection_id"
    }
    
    let userId: UserId
    let userDetails: UserWebSocketPayload<ExtraData>
    let serverDeterminesConnectionId: Bool

    init(userInfo: UserInfo<ExtraData>) {
        userId = userInfo.id
        userDetails = UserWebSocketPayload<ExtraData>(userInfo: userInfo)
        serverDeterminesConnectionId = true
    }
}

struct UserWebSocketPayload<ExtraData: ExtraDataTypes>: Encodable {
    let id: String
    let name: String?
    let imageURL: URL?
    let extraData: ExtraData.User
    
    init(userInfo: UserInfo<ExtraData>) {
        id = userInfo.id
        name = userInfo.name
        imageURL = userInfo.imageURL
        extraData = userInfo.extraData
    }
}
