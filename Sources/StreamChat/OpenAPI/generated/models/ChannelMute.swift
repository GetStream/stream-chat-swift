//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelMute: Codable, Hashable {
    public var createdAt: Date
    public var updatedAt: Date
    public var expires: Date? = nil
    public var channel: ChannelResponse? = nil
    public var user: UserObject? = nil

    public init(createdAt: Date, updatedAt: Date, expires: Date? = nil, channel: ChannelResponse? = nil, user: UserObject? = nil) {
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.expires = expires
        self.channel = channel
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case expires
        case channel
        case user
    }
}
