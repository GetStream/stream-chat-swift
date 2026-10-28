//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The channel of a scheduled message
final class ScheduledMessageChannelResponse: Sendable, Decodable {
    /// Channel CID (<type>:<id>)
    let cid: String
    /// Channel ID
    let id: String
    /// Channel image, from its custom data
    let image: String?
    /// Channel name, from its custom data
    let name: String?
    /// Channel type
    let type: String

    init(cid: String, id: String, image: String? = nil, name: String? = nil, type: String) {
        self.cid = cid
        self.id = id
        self.image = image
        self.name = name
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.cid = try container.decode(String.self, forKey: .cid)
        self.id = try container.decode(String.self, forKey: .id)
        self.image = try container.decodeIfPresent(String.self, forKey: .image)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.type = try container.decode(String.self, forKey: .type)
    }
}
