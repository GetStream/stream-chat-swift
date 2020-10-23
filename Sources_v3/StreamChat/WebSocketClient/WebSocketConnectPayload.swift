//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

struct WebSocketConnectPayload<ExtraData: UserExtraData>: Encodable {
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userDetails = "user_details"
        case serverDeterminesConnectionId = "server_determines_connection_id"
    }
    
    let userDetails: UserWebSocketPayload<ExtraData>
    let userId: UserId
    
    let serverDeterminesConnectionId = true
    
    init(userId: UserId, userRole: UserRole? = nil, extraData: ExtraData? = nil) {
        userDetails = UserWebSocketPayload(id: userId, userRole: userRole, extraData: extraData)
        self.userId = userId
    }
}

struct UserWebSocketPayload<ExtraData: UserExtraData>: Encodable {
    let userRoleRaw: String?
    let extraData: ExtraData?
    let id: String
    
    init(id: UserId, userRole: UserRole? = nil, extraData: ExtraData? = nil) {
        self.id = id
        userRoleRaw = userRole?.rawValue
        self.extraData = extraData
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case userRoleRaw = "role"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userRoleRaw, forKey: .userRoleRaw)
        try container.encode(id, forKey: .id)
        try extraData?.encode(to: encoder)
    }
}
