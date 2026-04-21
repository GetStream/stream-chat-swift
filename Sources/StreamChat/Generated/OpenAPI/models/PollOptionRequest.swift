//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollOptionRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var custom: [String: RawJSON]?
    var id: String
    var text: String?

    init(custom: [String: RawJSON]? = nil, id: String, text: String? = nil) {
        self.custom = custom
        self.id = id
        self.text = text
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case id
        case text
    }

    static func == (lhs: PollOptionRequest, rhs: PollOptionRequest) -> Bool {
        lhs.custom == rhs.custom &&
            lhs.id == rhs.id &&
            lhs.text == rhs.text
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(custom)
        hasher.combine(id)
        hasher.combine(text)
    }
}
