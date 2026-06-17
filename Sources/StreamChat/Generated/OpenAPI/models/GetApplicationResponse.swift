//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetApplicationResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var app: AppResponseFields
    /// Duration of the request in milliseconds
    var duration: String

    init(app: AppResponseFields, duration: String) {
        self.app = app
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case app
        case duration
    }

    static func == (lhs: GetApplicationResponse, rhs: GetApplicationResponse) -> Bool {
        lhs.app == rhs.app &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(app)
        hasher.combine(duration)
    }
}
