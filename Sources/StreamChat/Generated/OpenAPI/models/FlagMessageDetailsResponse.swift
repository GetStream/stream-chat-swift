//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FlagMessageDetailsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var pinChanged: Bool?
    var shouldEnrich: Bool?
    var skipPush: Bool?
    var updatedById: String?

    init(pinChanged: Bool? = nil, shouldEnrich: Bool? = nil, skipPush: Bool? = nil, updatedById: String? = nil) {
        self.pinChanged = pinChanged
        self.shouldEnrich = shouldEnrich
        self.skipPush = skipPush
        self.updatedById = updatedById
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case pinChanged = "pin_changed"
        case shouldEnrich = "should_enrich"
        case skipPush = "skip_push"
        case updatedById = "updated_by_id"
    }

    static func == (lhs: FlagMessageDetailsResponse, rhs: FlagMessageDetailsResponse) -> Bool {
        lhs.pinChanged == rhs.pinChanged &&
            lhs.shouldEnrich == rhs.shouldEnrich &&
            lhs.skipPush == rhs.skipPush &&
            lhs.updatedById == rhs.updatedById
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(pinChanged)
        hasher.combine(shouldEnrich)
        hasher.combine(skipPush)
        hasher.combine(updatedById)
    }
}
