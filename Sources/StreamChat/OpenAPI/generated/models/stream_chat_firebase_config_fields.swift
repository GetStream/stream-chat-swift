//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFirebaseConfigFields: Codable, Hashable {
    public var serverKey: String?
    
    public var apnTemplate: String
    
    public var credentialsJson: String?
    
    public var dataTemplate: String
    
    public var enabled: Bool
    
    public var notificationTemplate: String
    
    public init(serverKey: String?, apnTemplate: String, credentialsJson: String?, dataTemplate: String, enabled: Bool, notificationTemplate: String) {
        self.serverKey = serverKey
        
        self.apnTemplate = apnTemplate
        
        self.credentialsJson = credentialsJson
        
        self.dataTemplate = dataTemplate
        
        self.enabled = enabled
        
        self.notificationTemplate = notificationTemplate
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case serverKey = "server_key"
        
        case apnTemplate = "apn_template"
        
        case credentialsJson = "credentials_json"
        
        case dataTemplate = "data_template"
        
        case enabled
        
        case notificationTemplate = "notification_template"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(serverKey, forKey: .serverKey)
        
        try container.encode(apnTemplate, forKey: .apnTemplate)
        
        try container.encode(credentialsJson, forKey: .credentialsJson)
        
        try container.encode(dataTemplate, forKey: .dataTemplate)
        
        try container.encode(enabled, forKey: .enabled)
        
        try container.encode(notificationTemplate, forKey: .notificationTemplate)
    }
}
