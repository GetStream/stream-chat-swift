//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct BanRequest: Codable, Hashable {
    public var targetUserId: String
    public var bannedById: String? = nil
    public var id: String? = nil
    public var ipBan: Bool? = nil
    public var reason: String? = nil
    public var shadow: Bool? = nil
    public var timeout: Int? = nil
    public var timeoutSec: Int? = nil
    public var type: String? = nil
    public var bannedBy: UserRequest? = nil

    public init(targetUserId: String, bannedById: String? = nil, id: String? = nil, ipBan: Bool? = nil, reason: String? = nil, shadow: Bool? = nil, timeout: Int? = nil, timeoutSec: Int? = nil, type: String? = nil, bannedBy: UserRequest? = nil) {
        self.targetUserId = targetUserId
        self.bannedById = bannedById
        self.id = id
        self.ipBan = ipBan
        self.reason = reason
        self.shadow = shadow
        self.timeout = timeout
        self.timeoutSec = timeoutSec
        self.type = type
        self.bannedBy = bannedBy
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case targetUserId = "target_user_id"
        case bannedById = "banned_by_id"
        case id
        case ipBan = "ip_ban"
        case reason
        case shadow
        case timeout
        case timeoutSec = "timeout_sec"
        case type
        case bannedBy = "banned_by"
    }
}
