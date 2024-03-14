//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct NotificationSettings: Codable, Hashable {
    public var enabled: Bool
    public var callLiveStarted: EventNotificationSettings
    public var callNotification: EventNotificationSettings
    public var callRing: EventNotificationSettings
    public var sessionStarted: EventNotificationSettings

    public init(enabled: Bool, callLiveStarted: EventNotificationSettings, callNotification: EventNotificationSettings, callRing: EventNotificationSettings, sessionStarted: EventNotificationSettings) {
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
}