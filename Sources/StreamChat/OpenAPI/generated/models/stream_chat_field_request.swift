//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFieldRequest: Codable, Hashable {
    public var value: String?
    
    public var short: Bool?
    
    public var title: String?
    
    public init(value: String?, short: Bool?, title: String?) {
        self.value = value
        
        self.short = short
        
        self.title = title
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case value
        
        case short
        
        case title
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(value, forKey: .value)
        
        try container.encode(short, forKey: .short)
        
        try container.encode(title, forKey: .title)
    }
}
