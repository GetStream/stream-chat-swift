//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UserMutedEvent: Codable, Hashable, Event {
    public var createdAt: Date
    public var type: String
    public var targetUser: String? = nil
    public var targetUsers: [String]? = nil
    public var user: UserObject? = nil

    public init(createdAt: Date, type: String, targetUser: String? = nil, targetUsers: [String]? = nil, user: UserObject? = nil) {
        self.createdAt = createdAt
        self.type = type
        self.targetUser = targetUser
        self.targetUsers = targetUsers
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case type
        case targetUser = "target_user"
        case targetUsers = "target_users"
        case user
    }
}

extension UserMutedEvent: EventContainsCreationDate {}
extension UserMutedEvent: EventContainsUser {}
