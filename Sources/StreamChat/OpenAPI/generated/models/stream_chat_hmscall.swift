//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatHMSCall: Codable, Hashable {
    public var roomId: String
    
    public var roomName: String
    
    public init(roomId: String, roomName: String) {
        self.roomId = roomId
        
        self.roomName = roomName
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case roomId = "room_id"
        
        case roomName = "room_name"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(roomId, forKey: .roomId)
        
        try container.encode(roomName, forKey: .roomName)
    }
}
