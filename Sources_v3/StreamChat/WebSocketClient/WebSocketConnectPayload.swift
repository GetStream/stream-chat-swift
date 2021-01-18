//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

struct WebSocketConnectPayload: Encodable {
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userDetails = "user_details"
        case serverDeterminesConnectionId = "server_determines_connection_id"
    }
    
    let userId: UserId
    let userDetails: UserWebSocketPayload
    let serverDeterminesConnectionId: Bool

    init(userId: UserId) {
        self.userId = userId
        userDetails = UserWebSocketPayload(id: userId)
        serverDeterminesConnectionId = true
    }
}

struct UserWebSocketPayload: Encodable {
    let id: String
}
