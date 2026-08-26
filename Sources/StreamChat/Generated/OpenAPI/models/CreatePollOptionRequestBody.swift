//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreatePollOptionRequestBody: Sendable, Codable, JSONEncodable {
    /// Custom data for this object
    let custom: [String: RawJSON]?
    /// Option text
    let text: String

    init(custom: [String: RawJSON]? = nil, text: String) {
        self.custom = custom
        self.text = text
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case text
    }
}
