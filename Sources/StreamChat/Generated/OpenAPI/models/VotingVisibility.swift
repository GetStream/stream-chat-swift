//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Whether poll votes are attributed to the voter.
public final class VotingVisibility: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Votes are public and can be seen by everyone.
    public static let `public` = VotingVisibility(rawValue: "public")
    /// Votes are anonymous and cannot be attributed to individual users.
    public static let anonymous = VotingVisibility(rawValue: "anonymous")
}
