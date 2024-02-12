//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct GetApplicationResponse: Codable, Hashable {
    public var duration: String
    
    public var app: App
    
    public init(duration: String, app: App) {
        self.duration = duration
        
        self.app = app
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case app
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(app, forKey: .app)
    }
}
