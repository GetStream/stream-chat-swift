//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DeliveredMessagePayloadModel: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var cid: String?
    var id: String?

    init(cid: String? = nil, id: String? = nil) {
        self.cid = cid
        self.id = id
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case id
    }

    static func == (lhs: DeliveredMessagePayloadModel, rhs: DeliveredMessagePayloadModel) -> Bool {
        lhs.cid == rhs.cid &&
            lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(cid)
        hasher.combine(id)
    }
}
