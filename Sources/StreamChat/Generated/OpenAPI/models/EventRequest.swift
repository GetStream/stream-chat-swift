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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(parentId, forKey: .parentId)
        try container.encode(type, forKey: .type)
    }
}
