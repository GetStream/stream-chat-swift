//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollOptionRequestBody: Sendable, Encodable, JSONEncodable {
    let custom: [String: RawJSON]?
    let text: String?

    init(custom: [String: RawJSON]? = nil, text: String? = nil) {
        self.custom = custom
        self.text = text
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(text, forKey: .text)
    }
}
