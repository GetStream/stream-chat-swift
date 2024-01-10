//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatEventNotificationSettings: Codable, Hashable {
    public var apns: StreamChatAPNS
    
    public var enabled: Bool
    
    public init(apns: StreamChatAPNS, enabled: Bool) {
        self.apns = apns
        
        self.enabled = enabled
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case apns
        
        case enabled
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(apns, forKey: .apns)
        
        try container.encode(enabled, forKey: .enabled)
    }
}
