//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class EventRequest: Sendable, Encodable, JSONEncodable {
    let custom: [String: RawJSON]?
    let parentId: String?
    let type: String

    init(custom: [String: RawJSON]? = nil, parentId: String? = nil, type: String) {
        self.custom = custom
        self.parentId = parentId
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case parentId = "parent_id"
        case type
    }
}
