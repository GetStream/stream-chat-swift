//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol marking an DTO object containing ephemeral values, i.e. user online state, or unread counts. These values
/// need to be reset every time the database is initialized.
protocol EphemeralValuesContainer {
    /// Resets the ephemeral values of the container to their default state.
    func resetEphemeralValues()
}
