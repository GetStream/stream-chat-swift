//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UserBannedEvent: Codable, Hashable, Event {
    public var channelId: String
    public var channelType: String
    public var cid: String
    public var createdAt: Date
    public var shadow: Bool
    public var type: String
    public var createdBy: UserObject
    public var expiration: Date? = nil
    public var reason: String? = nil
    public var team: String? = nil
    public var user: UserObject? = nil

    public init(channelId: String, channelType: String, cid: String, createdAt: Date, shadow: Bool, type: String, createdBy: UserObject, expiration: Date? = nil, reason: String? = nil, team: String? = nil, user: UserObject? = nil) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.shadow = shadow
        self.type = type
        self.createdBy = createdBy
        self.expiration = expiration
        self.reason = reason
        self.team = team
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case shadow
        case type
        case createdBy = "created_by"
        case expiration
        case reason
        case team
        case user
    }
}

extension UserBannedEvent: EventContainsCreationDate {}
extension UserBannedEvent: EventContainsUser {}
