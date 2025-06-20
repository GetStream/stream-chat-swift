//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Data model for the new location info used in `createNewMessage`.
public struct NewLocationInfo {
    /// The initial latitude of the location.
    public let latitude: Double
    /// The initial longitude of the location.
    public let longitude: Double
    /// The end date of the location sharing if it is a live location.
    public let endAt: Date?
}
