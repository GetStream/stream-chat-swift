//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class OnlyUserID: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var id: String

    init(id: String) {
        self.id = id
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case id
    }

    static func == (lhs: OnlyUserID, rhs: OnlyUserID) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
