//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelCreatedEvent: Codable, Hashable, Event {
    public var createdAt: Date
    public var type: String

    public init(createdAt: Date, type: String) {
        self.createdAt = createdAt
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case type
    }
}

extension ChannelCreatedEvent: EventContainsCreationDate {}
