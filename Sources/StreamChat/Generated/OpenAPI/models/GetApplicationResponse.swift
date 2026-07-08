//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetApplicationResponse: Sendable, Codable, JSONEncodable {
    let app: AppSettings
    /// Duration of the request in milliseconds
    let duration: String

    init(app: AppSettings, duration: String) {
        self.app = app
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case app
        case duration
    }
}

extension GetApplicationResponse: Hashable {
    static func == (lhs: GetApplicationResponse, rhs: GetApplicationResponse) -> Bool {
        lhs.app == rhs.app &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(app)
        hasher.combine(duration)
    }
}
