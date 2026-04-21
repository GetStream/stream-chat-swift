//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MarkReadResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var event: MarkReadResponseEvent?

    init(duration: String, event: MarkReadResponseEvent? = nil) {
        self.duration = duration
        self.event = event
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case event
    }

    static func == (lhs: MarkReadResponse, rhs: MarkReadResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.event == rhs.event
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(event)
    }
}
