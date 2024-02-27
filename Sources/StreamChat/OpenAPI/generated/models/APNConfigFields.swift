//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct APNConfigFields: Codable, Hashable {
    public var development: Bool
    public var enabled: Bool
    public var notificationTemplate: String
    public var authKey: String? = nil
    public var authType: String? = nil
    public var bundleId: String? = nil
    public var host: String? = nil
    public var keyId: String? = nil
    public var p12Cert: String? = nil
    public var teamId: String? = nil

    public init(development: Bool, enabled: Bool, notificationTemplate: String, authKey: String? = nil, authType: String? = nil, bundleId: String? = nil, host: String? = nil, keyId: String? = nil, p12Cert: String? = nil, teamId: String? = nil) {
        self.development = development
        self.enabled = enabled
        self.notificationTemplate = notificationTemplate
        self.authKey = authKey
        self.authType = authType
        self.bundleId = bundleId
        self.host = host
        self.keyId = keyId
        self.p12Cert = p12Cert
        self.teamId = teamId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case development
        case enabled
        case notificationTemplate = "notification_template"
        case authKey = "auth_key"
        case authType = "auth_type"
        case bundleId = "bundle_id"
        case host
        case keyId = "key_id"
        case p12Cert = "p12_cert"
        case teamId = "team_id"
    }
}