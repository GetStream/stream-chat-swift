//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatDeleteChannelsResult: Codable, Hashable {
    public var error: String?
    
    public var status: String
    
    public init(error: String?, status: String) {
        self.error = error
        
        self.status = status
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case error
        
        case status
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(error, forKey: .error)
        
        try container.encode(status, forKey: .status)
    }
}
