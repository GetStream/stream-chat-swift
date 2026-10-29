//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollOptionPayload: Sendable, Decodable {
    let custom: [String: RawJSON]
    let id: String
    let text: String

    init(custom: [String: RawJSON], id: String, text: String) {
        self.custom = custom
        self.id = id
        self.text = text
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.custom = try container.decode([String: RawJSON].self, forKey: .custom)
        self.id = try container.decode(String.self, forKey: .id)
        self.text = try container.decode(String.self, forKey: .text)
    }
}
