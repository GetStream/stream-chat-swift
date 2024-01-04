//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallType: Codable, Hashable {
    public var updatedAt: String
    
    public var appPK: Int
    
    public var createdAt: String
    
    public var name: String
    
    public var notificationSettings: StreamChatNotificationSettings?
    
    public var pK: Int
    
    public var settings: StreamChatCallSettings?
    
    public init(updatedAt: String, appPK: Int, createdAt: String, name: String, notificationSettings: StreamChatNotificationSettings?, pK: Int, settings: StreamChatCallSettings?) {
        self.updatedAt = updatedAt
        
        self.appPK = appPK
        
        self.createdAt = createdAt
        
        self.name = name
        
        self.notificationSettings = notificationSettings
        
        self.pK = pK
        
        self.settings = settings
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case updatedAt = "UpdatedAt"
        
        case appPK = "AppPK"
        
        case createdAt = "CreatedAt"
        
        case name = "Name"
        
        case notificationSettings = "NotificationSettings"
        
        case pK = "PK"
        
        case settings = "Settings"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(appPK, forKey: .appPK)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(notificationSettings, forKey: .notificationSettings)
        
        try container.encode(pK, forKey: .pK)
        
        try container.encode(settings, forKey: .settings)
    }
}
