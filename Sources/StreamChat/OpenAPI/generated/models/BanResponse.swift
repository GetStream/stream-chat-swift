//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct BanResponse: Codable, Hashable {
    public var createdAt: Date
    public var expires: Date? = nil
    public var reason: String? = nil
    public var shadow: Bool? = nil
    public var bannedBy: UserObject? = nil
    public var channel: ChannelResponse? = nil
    public var user: UserObject? = nil

    public init(createdAt: Date, expires: Date? = nil, reason: String? = nil, shadow: Bool? = nil, bannedBy: UserObject? = nil, channel: ChannelResponse? = nil, user: UserObject? = nil) {
        self.createdAt = createdAt
        self.expires = expires
        self.reason = reason
        self.shadow = shadow
        self.bannedBy = bannedBy
        self.channel = channel
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case expires
        case reason
        case shadow
        case bannedBy = "banned_by"
        case channel
        case user
    }
}