//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DeliveredMessagePayload: Sendable, Codable, JSONEncodable {
    let cid: String?
    let id: String?

    init(cid: String? = nil, id: String? = nil) {
        self.cid = cid
        self.id = id
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case id
    }
}
