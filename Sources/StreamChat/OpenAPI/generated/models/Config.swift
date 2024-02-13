//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Config: Codable, Hashable {
    public var appCertificate: String
    public var appId: String
    public var defaultRole: String? = nil
    public var roleMap: [String: String]? = nil

    public init(appCertificate: String, appId: String, defaultRole: String? = nil, roleMap: [String: String]? = nil) {
        self.appCertificate = appCertificate
        self.appId = appId
        self.defaultRole = defaultRole
        self.roleMap = roleMap
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case appCertificate = "app_certificate"
        case appId = "app_id"
        case defaultRole = "default_role"
        case roleMap = "role_map"
    }
}
