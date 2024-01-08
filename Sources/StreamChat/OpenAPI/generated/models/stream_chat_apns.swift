//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAPNS: Codable, Hashable {
    public var title: String
    
    public var body: String
    
    public init(title: String, body: String) {
        self.title = title
        
        self.body = body
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case title
        
        case body
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(title, forKey: .title)
        
        try container.encode(body, forKey: .body)
    }
}
