//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type that represents the supported push providers.
public struct PushProvider: RawRepresentable, Hashable, ExpressibleByStringLiteral {
    public static let firebase: Self = "firebase"
    public static let apn: Self = "apn"

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}
