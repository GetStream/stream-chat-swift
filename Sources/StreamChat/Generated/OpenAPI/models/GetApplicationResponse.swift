//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetApplicationResponse: Sendable, Codable, JSONEncodable {
    let app: AppResponseFields

    init(app: AppResponseFields) {
        self.app = app
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case app
    }
}
