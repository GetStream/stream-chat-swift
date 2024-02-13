//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UserPresenceChangedEvent: Codable, Hashable, Event {
    public var createdAt: Date
    public var type: String
    public var user: UserObject? = nil

    public init(createdAt: Date, type: String, user: UserObject? = nil) {
        self.createdAt = createdAt
        self.type = type
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case type
        case user
    }
}

extension UserPresenceChangedEvent: EventContainsCreationDate {}
extension UserPresenceChangedEvent: EventContainsUser {}
