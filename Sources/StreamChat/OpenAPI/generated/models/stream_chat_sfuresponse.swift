//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSFUResponse: Codable, Hashable {
    public var wsEndpoint: String
    
    public var edgeName: String
    
    public var url: String
    
    public init(wsEndpoint: String, edgeName: String, url: String) {
        self.wsEndpoint = wsEndpoint
        
        self.edgeName = edgeName
        
        self.url = url
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case wsEndpoint = "ws_endpoint"
        
        case edgeName = "edge_name"
        
        case url
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(wsEndpoint, forKey: .wsEndpoint)
        
        try container.encode(edgeName, forKey: .edgeName)
        
        try container.encode(url, forKey: .url)
    }
}
