//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct HealthCheckEvent: Codable, Hashable, Event {
    public var cid: String
    public var connectionId: String
    public var createdAt: Date
    public var type: String
    public var me: OwnUser? = nil

    public init(cid: String, connectionId: String, createdAt: Date, type: String, me: OwnUser? = nil) {
        self.cid = cid
        self.connectionId = connectionId
        self.createdAt = createdAt
        self.type = type
        self.me = me
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case connectionId = "connection_id"
        case createdAt = "created_at"
        case type
        case me
    }
}

extension HealthCheckEvent: EventContainsCreationDate {}
extension HealthCheckEvent: EventContainsCurrentUser {}
