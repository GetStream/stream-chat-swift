//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetRepliesResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var messages: [MessageResponse]

    init(duration: String, messages: [MessageResponse]) {
        self.duration = duration
        self.messages = messages
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case messages
    }

    static func == (lhs: GetRepliesResponse, rhs: GetRepliesResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.messages == rhs.messages
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(messages)
    }
}
