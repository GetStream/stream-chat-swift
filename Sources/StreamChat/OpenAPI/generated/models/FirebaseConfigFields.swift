//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct FirebaseConfigFields: Codable, Hashable {
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
}
