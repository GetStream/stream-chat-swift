//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationSettings: Codable, Hashable {
    public var callLiveStarted: StreamChatEventNotificationSettings
    
    public var callNotification: StreamChatEventNotificationSettings
    
    public var callRing: StreamChatEventNotificationSettings
    
    public var enabled: Bool
    
    public var sessionStarted: StreamChatEventNotificationSettings
    
    public init(callLiveStarted: StreamChatEventNotificationSettings, callNotification: StreamChatEventNotificationSettings, callRing: StreamChatEventNotificationSettings, enabled: Bool, sessionStarted: StreamChatEventNotificationSettings) {
        self.callLiveStarted = callLiveStarted
        
        self.callNotification = callNotification
        
        self.callRing = callRing
        
        self.enabled = enabled
        
        self.sessionStarted = sessionStarted
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callLiveStarted = "call_live_started"
        
        case callNotification = "call_notification"
        
        case callRing = "call_ring"
        
        case enabled
        
        case sessionStarted = "session_started"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(callLiveStarted, forKey: .callLiveStarted)
        
        try container.encode(callNotification, forKey: .callNotification)
        
        try container.encode(callRing, forKey: .callRing)
        
        try container.encode(enabled, forKey: .enabled)
        
        try container.encode(sessionStarted, forKey: .sessionStarted)
    }
}
