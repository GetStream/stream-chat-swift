//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageActionResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var message: MessageResponse?

    init(duration: String, message: MessageResponse? = nil) {
        self.duration = duration
        self.message = message
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case message
    }

    static func == (lhs: MessageActionResponse, rhs: MessageActionResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.message == rhs.message
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(message)
    }
}
