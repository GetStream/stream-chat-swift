//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetApplicationResponse: Sendable, Decodable {
    let app: AppSettings
    /// Duration of the request in milliseconds
    let duration: String

    init(
        app: AppSettings,
        duration: String
    ) {
        self.app = app
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case app
        case duration
    }
}
