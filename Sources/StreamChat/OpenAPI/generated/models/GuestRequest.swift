//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct GuestRequest: Codable, Hashable {
    public var user: UserObjectRequest

    public init(user: UserObjectRequest) {
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user, forKey: .user)
    }
}
