//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class User: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var data: [String: RawJSON]?
    var id: String

    init(data: [String: RawJSON]? = nil, id: String) {
        self.data = data
        self.id = id
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case data
        case id
    }

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.data == rhs.data &&
            lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(data)
        hasher.combine(id)
    }
}
