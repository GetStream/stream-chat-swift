//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class EventRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var custom: [String: RawJSON]?
    var parentId: String?
    var type: String

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

    static func == (lhs: EventRequest, rhs: EventRequest) -> Bool {
        lhs.custom == rhs.custom &&
            lhs.parentId == rhs.parentId &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(custom)
        hasher.combine(parentId)
        hasher.combine(type)
    }
}
