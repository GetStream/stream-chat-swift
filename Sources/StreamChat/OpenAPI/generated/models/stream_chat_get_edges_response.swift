//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGetEdgesResponse: Codable, Hashable {
    public var duration: String
    
    public var edges: [StreamChatEdgeResponse]
    
    public init(duration: String, edges: [StreamChatEdgeResponse]) {
        self.duration = duration
        
        self.edges = edges
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case edges
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(edges, forKey: .edges)
    }
}
