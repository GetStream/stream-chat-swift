//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct CallType: Codable, Hashable {
    public var appPK: Int
    public var createdAt: Date
    public var externalStorage: String
    public var name: String
    public var pK: Int
    public var updatedAt: Date
    public var notificationSettings: NotificationSettings? = nil
    public var settings: CallSettings? = nil

    public init(appPK: Int, createdAt: Date, externalStorage: String, name: String, pK: Int, updatedAt: Date, notificationSettings: NotificationSettings? = nil, settings: CallSettings? = nil) {
        self.appPK = appPK
        self.createdAt = createdAt
        self.externalStorage = externalStorage
        self.name = name
        self.pK = pK
        self.updatedAt = updatedAt
        self.notificationSettings = notificationSettings
        self.settings = settings
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case appPK = "AppPK"
        case createdAt = "CreatedAt"
        case externalStorage = "ExternalStorage"
        case name = "Name"
        case pK = "PK"
        case updatedAt = "UpdatedAt"
        case notificationSettings = "NotificationSettings"
        case settings = "Settings"
    }
}
