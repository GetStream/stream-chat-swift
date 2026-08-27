//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class PollOptionRequestBody: Sendable, Encodable, JSONEncodable {
    let custom: [String: RawJSON]?
    let text: String?

    init(custom: [String: RawJSON]? = nil, text: String? = nil) {
        self.custom = custom
        self.text = text
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case text
    }
}
