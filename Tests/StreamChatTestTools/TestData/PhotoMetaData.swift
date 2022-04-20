//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public struct PhotoMetadata: Codable, Equatable {
    public struct Location: Codable, Equatable {
        public let longitude: Double
        public let latitude: Double
    }

    public let location: Location
    public let comment: String

    public static var random: Self {
        .init(
            location: .init(
                longitude: .random(in: 0...100),
                latitude: .random(in: 0...100)
            ),
            comment: .unique
        )
    }
}
