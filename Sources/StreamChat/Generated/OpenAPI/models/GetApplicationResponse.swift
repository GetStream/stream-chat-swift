//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetApplicationResponse: Sendable, Decodable {
    let app: AppSettings

    init(app: AppSettings) {
        self.app = app
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case app
    }
}
