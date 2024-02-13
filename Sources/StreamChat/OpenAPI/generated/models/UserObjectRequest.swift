//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UserObjectRequest: Codable, Hashable {
    public var id: String
    public var invisible: Bool? = nil
    public var language: String? = nil
    public var role: String? = nil
    public var teams: [String]? = nil
    public var custom: [String: RawJSON]? = nil
    public var pushNotifications: PushNotificationSettingsRequest? = nil

    public init(id: String, invisible: Bool? = nil, language: String? = nil, role: String? = nil, teams: [String]? = nil, custom: [String: RawJSON]? = nil, pushNotifications: PushNotificationSettingsRequest? = nil) {
        self.id = id
        self.invisible = invisible
        self.language = language
        self.role = role
        self.teams = teams
        self.custom = custom
        self.pushNotifications = pushNotifications
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case invisible
        case language
        case role
        case teams
        case custom
        case pushNotifications = "push_notifications"
    }
}
