//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatPushNotificationSettings: Codable, Hashable {
    public var disabledUntil: Date?
    
    public var disabled: Bool?
    
    public init(disabledUntil: Date?, disabled: Bool?) {
        self.disabledUntil = disabledUntil
        
        self.disabled = disabled
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case disabledUntil = "disabled_until"
        
        case disabled
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(disabledUntil, forKey: .disabledUntil)
        
        try container.encode(disabled, forKey: .disabled)
    }
}
