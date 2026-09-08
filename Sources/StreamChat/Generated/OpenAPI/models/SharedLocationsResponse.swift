//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SharedLocationsResponse: Sendable, Decodable {
    let activeLiveLocations: [SharedLocation]

    init(activeLiveLocations: [SharedLocation]) {
        self.activeLiveLocations = activeLiveLocations
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case activeLiveLocations = "active_live_locations"
    }
}
