//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreatePollOptionRequestBody: Sendable, Encodable, JSONEncodable {
    /// Custom data for this object
    let custom: [String: RawJSON]?
    /// Option text
    let text: String

    init(custom: [String: RawJSON]? = nil, text: String) {
        self.custom = custom
        self.text = text
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encode(text, forKey: .text)
    }
}
