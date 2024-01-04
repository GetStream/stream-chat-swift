//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatICEServer: Codable, Hashable {
    public var username: String
    
    public var password: String
    
    public var urls: [String]
    
    public init(username: String, password: String, urls: [String]) {
        self.username = username
        
        self.password = password
        
        self.urls = urls
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case username
        
        case password
        
        case urls
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(username, forKey: .username)
        
        try container.encode(password, forKey: .password)
        
        try container.encode(urls, forKey: .urls)
    }
}
