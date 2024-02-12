//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct CallType: Codable, Hashable {
    public var appPK: Int
    public var createdAt: Date
    public var name: String
    public var pK: Int
    public var updatedAt: Date
    public var notificationSettings: NotificationSettings? = nil
    public var settings: CallSettings? = nil

    public init(appPK: Int, createdAt: Date, name: String, pK: Int, updatedAt: Date, notificationSettings: NotificationSettings? = nil, settings: CallSettings? = nil) {
        self.appPK = appPK
        self.createdAt = createdAt
        self.name = name
        self.pK = pK
        self.updatedAt = updatedAt
        self.notificationSettings = notificationSettings
        self.settings = settings
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case appPK = "AppPK"
        case createdAt = "CreatedAt"
        case name = "Name"
        case pK = "PK"
        case updatedAt = "UpdatedAt"
        case notificationSettings = "NotificationSettings"
        case settings = "Settings"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appPK, forKey: .appPK)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(name, forKey: .name)
        try container.encode(pK, forKey: .pK)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(notificationSettings, forKey: .notificationSettings)
        try container.encode(settings, forKey: .settings)
    }
}
