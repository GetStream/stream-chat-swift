//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DeliveredMessagePayload: Sendable, Encodable, JSONEncodable {
    let cid: String?
    let id: String?

    init(cid: String? = nil, id: String? = nil) {
        self.cid = cid
        self.id = id
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(cid, forKey: .cid)
        try container.encodeIfPresent(id, forKey: .id)
    }
}
