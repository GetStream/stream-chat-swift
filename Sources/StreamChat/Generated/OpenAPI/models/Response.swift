//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class Response: Sendable, Codable, JSONEncodable {
    /// Duration of the request in milliseconds
    let duration: String

    init(duration: String) {
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
    }
}
