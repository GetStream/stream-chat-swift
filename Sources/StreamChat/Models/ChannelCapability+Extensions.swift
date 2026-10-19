//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension ChannelCapability: ExpressibleByStringLiteral {
    public convenience init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

public extension ChannelCapability {
    /// Ability to join a call.
    @available(*, deprecated, message: "Calling capabilities are no longer part of channel capabilities.")
    static let joinCall: ChannelCapability = "join-call"

    /// Ability to create a call.
    @available(*, deprecated, message: "Calling capabilities are no longer part of channel capabilities.")
    static let createCall: ChannelCapability = "create-call"
}
