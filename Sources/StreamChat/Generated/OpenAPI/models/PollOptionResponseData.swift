//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollOptionResponseData: Sendable, Codable, JSONEncodable {
    let custom: [String: RawJSON]
    let id: String
    let text: String

    init(
        custom: [String: RawJSON],
        id: String,
        text: String
    ) {
        self.custom = custom
        self.id = id
        self.text = text
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case id
        case text
    }
}
