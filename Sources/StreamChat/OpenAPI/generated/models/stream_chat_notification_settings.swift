//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationSettings: Codable, Hashable {
    public var enabled: Bool
    
    public var callLiveStarted: StreamChatEventNotificationSettings
    
    public var callNotification: StreamChatEventNotificationSettings
    
    public var callRing: StreamChatEventNotificationSettings
    
    public var sessionStarted: StreamChatEventNotificationSettings
    
    public init(enabled: Bool, callLiveStarted: StreamChatEventNotificationSettings, callNotification: StreamChatEventNotificationSettings, callRing: StreamChatEventNotificationSettings, sessionStarted: StreamChatEventNotificationSettings) {
        self.enabled = enabled
        
        self.callLiveStarted = callLiveStarted
        
        self.callNotification = callNotification
        
        self.callRing = callRing
        
        self.sessionStarted = sessionStarted
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        
        case callLiveStarted = "call_live_started"
        
        case callNotification = "call_notification"
        
        case callRing = "call_ring"
        
        case sessionStarted = "session_started"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(enabled, forKey: .enabled)
        
        try container.encode(callLiveStarted, forKey: .callLiveStarted)
        
        try container.encode(callNotification, forKey: .callNotification)
        
        try container.encode(callRing, forKey: .callRing)
        
        try container.encode(sessionStarted, forKey: .sessionStarted)
    }
}
