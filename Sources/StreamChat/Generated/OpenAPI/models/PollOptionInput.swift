//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollOptionInput: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var custom: [String: RawJSON]?
    var text: String?

    init(custom: [String: RawJSON]? = nil, text: String? = nil) {
        self.custom = custom
        self.text = text
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case text
    }

    static func == (lhs: PollOptionInput, rhs: PollOptionInput) -> Bool {
        lhs.custom == rhs.custom &&
            lhs.text == rhs.text
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(custom)
        hasher.combine(text)
    }
}
