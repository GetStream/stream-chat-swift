//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCredentials: Codable, Hashable {
    public var iceServers: [StreamChatICEServer]
    
    public var server: StreamChatSFUResponse
    
    public var token: String
    
    public init(iceServers: [StreamChatICEServer], server: StreamChatSFUResponse, token: String) {
        self.iceServers = iceServers
        
        self.server = server
        
        self.token = token
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case iceServers = "ice_servers"
        
        case server
        
        case token
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(iceServers, forKey: .iceServers)
        
        try container.encode(server, forKey: .server)
        
        try container.encode(token, forKey: .token)
    }
}
