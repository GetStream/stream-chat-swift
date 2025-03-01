//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

struct MemberUpdatePayload: Encodable, Equatable {
    let archived: Bool?
    let pinned: Bool?
    let extraData: [String: RawJSON]?
    
    init(
        archived: Bool? = nil,
        pinned: Bool? = nil,
        extraData: [String: RawJSON]? = nil
    ) {
        self.archived = archived
        self.pinned = pinned
        self.extraData = extraData
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(archived, forKey: .archived)
        try container.encodeIfPresent(pinned, forKey: .pinned)
        if let extraData, !extraData.isEmpty {
            try extraData.encode(to: encoder)
        }
    }
}

extension MemberUpdatePayload {
    enum CodingKeys: String, CodingKey {
        case archived
        case pinned
    }
}
