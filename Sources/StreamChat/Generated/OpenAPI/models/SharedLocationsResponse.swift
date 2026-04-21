//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SharedLocationsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var activeLiveLocations: [SharedLocationResponseData]
    var duration: String

    init(activeLiveLocations: [SharedLocationResponseData], duration: String) {
        self.activeLiveLocations = activeLiveLocations
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case activeLiveLocations = "active_live_locations"
        case duration
    }

    static func == (lhs: SharedLocationsResponse, rhs: SharedLocationsResponse) -> Bool {
        lhs.activeLiveLocations == rhs.activeLiveLocations &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(activeLiveLocations)
        hasher.combine(duration)
    }
}
