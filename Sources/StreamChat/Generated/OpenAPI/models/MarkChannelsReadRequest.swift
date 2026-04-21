//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MarkChannelsReadRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Map of channel ID to last read message ID
    var readByChannel: [String: String]?

    init(readByChannel: [String: String]? = nil) {
        self.readByChannel = readByChannel
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case readByChannel = "read_by_channel"
    }

    static func == (lhs: MarkChannelsReadRequest, rhs: MarkChannelsReadRequest) -> Bool {
        lhs.readByChannel == rhs.readByChannel
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(readByChannel)
    }
}
