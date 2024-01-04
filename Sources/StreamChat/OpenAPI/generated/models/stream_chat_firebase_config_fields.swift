//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFirebaseConfigFields: Codable, Hashable {
    public var dataTemplate: String
    
    public var enabled: Bool
    
    public var notificationTemplate: String
    
    public var serverKey: String?
    
    public var apnTemplate: String
    
    public var credentialsJson: String?
    
    public init(dataTemplate: String, enabled: Bool, notificationTemplate: String, serverKey: String?, apnTemplate: String, credentialsJson: String?) {
        self.dataTemplate = dataTemplate
        
        self.enabled = enabled
        
        self.notificationTemplate = notificationTemplate
        
        self.serverKey = serverKey
        
        self.apnTemplate = apnTemplate
        
        self.credentialsJson = credentialsJson
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case dataTemplate = "data_template"
        
        case enabled
        
        case notificationTemplate = "notification_template"
        
        case serverKey = "server_key"
        
        case apnTemplate = "apn_template"
        
        case credentialsJson = "credentials_json"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(dataTemplate, forKey: .dataTemplate)
        
        try container.encode(enabled, forKey: .enabled)
        
        try container.encode(notificationTemplate, forKey: .notificationTemplate)
        
        try container.encode(serverKey, forKey: .serverKey)
        
        try container.encode(apnTemplate, forKey: .apnTemplate)
        
        try container.encode(credentialsJson, forKey: .credentialsJson)
    }
}
