//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFirebaseConfigFields: Codable, Hashable {
    public var apnTemplate: String
    
    public var dataTemplate: String
    
    public var enabled: Bool
    
    public var notificationTemplate: String
    
    public var credentialsJson: String? = nil
    
    public var serverKey: String? = nil
    
    public init(apnTemplate: String, dataTemplate: String, enabled: Bool, notificationTemplate: String, credentialsJson: String? = nil, serverKey: String? = nil) {
        self.apnTemplate = apnTemplate
        
        self.dataTemplate = dataTemplate
        
        self.enabled = enabled
        
        self.notificationTemplate = notificationTemplate
        
        self.credentialsJson = credentialsJson
        
        self.serverKey = serverKey
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case apnTemplate = "apn_template"
        
        case dataTemplate = "data_template"
        
        case enabled
        
        case notificationTemplate = "notification_template"
        
        case credentialsJson = "credentials_json"
        
        case serverKey = "server_key"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(apnTemplate, forKey: .apnTemplate)
        
        try container.encode(dataTemplate, forKey: .dataTemplate)
        
        try container.encode(enabled, forKey: .enabled)
        
        try container.encode(notificationTemplate, forKey: .notificationTemplate)
        
        try container.encode(credentialsJson, forKey: .credentialsJson)
        
        try container.encode(serverKey, forKey: .serverKey)
    }
}
