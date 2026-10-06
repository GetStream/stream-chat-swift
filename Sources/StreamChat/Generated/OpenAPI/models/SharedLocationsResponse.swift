//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SharedLocationsResponse: Sendable, Decodable {
    let activeLiveLocations: [SharedLocation]

    init(activeLiveLocations: [SharedLocation]) {
        self.activeLiveLocations = activeLiveLocations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.activeLiveLocations = try container.decode(
            [SharedLocation].self,
            forKey: .activeLiveLocations
        )
    }
}
