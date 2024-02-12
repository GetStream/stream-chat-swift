//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct QueryBannedUsersResponse: Codable, Hashable {
    public var duration: String
    public var bans: [BanResponse?]

    public init(duration: String, bans: [BanResponse?]) {
        self.duration = duration
        self.bans = bans
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case bans
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(duration, forKey: .duration)
        try container.encode(bans, forKey: .bans)
    }
}
