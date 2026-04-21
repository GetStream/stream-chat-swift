//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreatePollOptionRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var custom: [String: RawJSON]?
    /// Option text
    var text: String

    init(custom: [String: RawJSON]? = nil, text: String) {
        self.custom = custom
        self.text = text
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case custom = "Custom"
        case text
    }

    static func == (lhs: CreatePollOptionRequest, rhs: CreatePollOptionRequest) -> Bool {
        lhs.custom == rhs.custom &&
            lhs.text == rhs.text
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(custom)
        hasher.combine(text)
    }
}
