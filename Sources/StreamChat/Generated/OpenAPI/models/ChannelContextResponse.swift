//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelContextResponse: Sendable, Codable, JSONEncodable {
    /// Channel CID (<type>:<id>)
    let cid: String
    /// User response object
    let createdBy: UserPayload?
    /// Channel ID
    let id: String
    /// Channel type
    let type: String

    init(
        cid: String,
        createdBy: UserPayload? = nil,
        id: String,
        type: String
    ) {
        self.cid = cid
        self.createdBy = createdBy
        self.id = id
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case createdBy = "created_by"
        case id
        case type
    }
}
