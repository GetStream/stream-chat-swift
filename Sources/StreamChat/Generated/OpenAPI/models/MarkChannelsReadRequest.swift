//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MarkChannelsReadRequest: Sendable, Encodable, JSONEncodable {
    /// Map of channel ID to last read message ID
    let readByChannel: [String: String]?

    init(readByChannel: [String: String]? = nil) {
        self.readByChannel = readByChannel
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case readByChannel = "read_by_channel"
    }
}
