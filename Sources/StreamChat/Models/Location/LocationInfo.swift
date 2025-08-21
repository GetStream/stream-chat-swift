//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The location information.
public struct LocationInfo: Sendable {
    /// The location latitude.
    public var latitude: Double
    /// The location longitude.
    public var longitude: Double

    public init(
        latitude: Double,
        longitude: Double
    ) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
