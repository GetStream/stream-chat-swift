//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// Describes the pinning expiration
public struct MessagePinning: Equatable {
    /// The expiration date of the pinning. Infinite expiration in case it is `nil`.
    public let expirationDate: Date?

    /// Private initialiser. The static initialisers should be used for better syntax and ease of use.
    init(expirationDate: Date?) {
        self.expirationDate = expirationDate
    }

    /// Pins a message with infinite expiration.
    public static let noExpiration = MessagePinning(expirationDate: nil)

    /// Pins a message.
    /// - Parameter date: The date when the message will be unpinned.
    public static func expirationDate(_ date: Date) -> Self {
        .init(expirationDate: date)
    }

    /// Pins a message.
    /// - Parameter time: The amount of seconds the message will be pinned.
    public static func expirationTime(_ time: TimeInterval) -> Self {
        .init(expirationDate: Date().addingTimeInterval(time))
    }
}
