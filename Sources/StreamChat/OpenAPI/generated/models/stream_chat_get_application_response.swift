//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGetApplicationResponse: Codable, Hashable {
    public var app: StreamChatApp
    
    public var duration: String
    
    public init(app: StreamChatApp, duration: String) {
        self.app = app
        
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case app
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(app, forKey: .app)
        
        try container.encode(duration, forKey: .duration)
    }
}
