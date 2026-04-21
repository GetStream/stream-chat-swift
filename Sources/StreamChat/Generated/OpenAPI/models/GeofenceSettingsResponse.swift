//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GeofenceSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var names: [String]

    init(names: [String]) {
        self.names = names
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case names
    }

    static func == (lhs: GeofenceSettingsResponse, rhs: GeofenceSettingsResponse) -> Bool {
        lhs.names == rhs.names
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(names)
    }
}
