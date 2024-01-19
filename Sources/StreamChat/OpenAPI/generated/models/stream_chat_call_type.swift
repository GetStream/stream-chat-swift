//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallType: Codable, Hashable {
    public var pK: Int
    
    public var settings: StreamChatCallSettings?
    
    public var updatedAt: Date
    
    public var appPK: Int
    
    public var createdAt: Date
    
    public var name: String
    
    public var notificationSettings: StreamChatNotificationSettings?
    
    public init(pK: Int, settings: StreamChatCallSettings?, updatedAt: Date, appPK: Int, createdAt: Date, name: String, notificationSettings: StreamChatNotificationSettings?) {
        self.pK = pK
        
        self.settings = settings
        
        self.updatedAt = updatedAt
        
        self.appPK = appPK
        
        self.createdAt = createdAt
        
        self.name = name
        
        self.notificationSettings = notificationSettings
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case pK = "PK"
        
        case settings = "Settings"
        
        case updatedAt = "UpdatedAt"
        
        case appPK = "AppPK"
        
        case createdAt = "CreatedAt"
        
        case name = "Name"
        
        case notificationSettings = "NotificationSettings"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(pK, forKey: .pK)
        
        try container.encode(settings, forKey: .settings)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(appPK, forKey: .appPK)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(notificationSettings, forKey: .notificationSettings)
    }
}
