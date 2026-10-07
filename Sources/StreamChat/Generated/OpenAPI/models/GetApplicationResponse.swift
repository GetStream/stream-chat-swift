//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Basic response information
final class GetApplicationResponse: Sendable, Decodable {
    /// A type representing the app settings.
    let app: AppSettings

    init(app: AppSettings) {
        self.app = app
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.app = try container.decode(AppSettings.self, forKey: .app)
    }
}
