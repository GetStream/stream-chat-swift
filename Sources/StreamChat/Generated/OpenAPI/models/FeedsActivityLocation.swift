//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FeedsActivityLocation: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var lat: Float
    var lng: Float

    init(lat: Float, lng: Float) {
        self.lat = lat
        self.lng = lng
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case lat
        case lng
    }

    static func == (lhs: FeedsActivityLocation, rhs: FeedsActivityLocation) -> Bool {
        lhs.lat == rhs.lat &&
            lhs.lng == rhs.lng
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(lat)
        hasher.combine(lng)
    }
}
