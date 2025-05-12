//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The location information.
public struct LocationInfo {
    public var latitude: Double
    public var longitude: Double
    public var extraData: [String: RawJSON]?

    public init(
        latitude: Double,
        longitude: Double,
        extraData: [String: RawJSON]? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.extraData = extraData
    }
}
