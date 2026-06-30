//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetApplicationResponse: Sendable, Codable, JSONEncodable {
    let app: AppResponseFields
    /// Duration of the request in milliseconds
    let duration: String

    init(app: AppResponseFields, duration: String) {
        self.app = app
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case app
        case duration
    }
}
