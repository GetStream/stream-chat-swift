//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum UserPayloadsCodingKeys: String, CodingKey {
    case id
    case name
    case imageURL = "image"
    case role
    case isOnline = "online"
    case isBanned = "banned"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case lastActiveAt = "last_active"
    case isInvisible = "invisible"
    case teams
    case unreadChannelsCount = "unread_channels"
    case unreadMessagesCount = "total_unread_count"
    case isAnonymous = "anon"
    case privacySettings = "privacy_settings"
    case teamsRole = "teams_role"
}
