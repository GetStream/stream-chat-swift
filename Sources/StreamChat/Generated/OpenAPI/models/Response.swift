//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class Response: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String

    init(duration: String) {
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
    }

    static func == (lhs: Response, rhs: Response) -> Bool {
        lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
    }
}
