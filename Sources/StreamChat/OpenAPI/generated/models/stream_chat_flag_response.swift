//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFlagResponse: Codable, Hashable {
    public var duration: String
    
    public var flag: StreamChatFlag?
    
    public init(duration: String, flag: StreamChatFlag?) {
        self.duration = duration
        
        self.flag = flag
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case flag
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(flag, forKey: .flag)
    }
}
