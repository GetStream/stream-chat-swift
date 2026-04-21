//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreateGuestRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var user: UserRequest

    init(user: UserRequest) {
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case user
    }

    static func == (lhs: CreateGuestRequest, rhs: CreateGuestRequest) -> Bool {
        lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(user)
    }
}
