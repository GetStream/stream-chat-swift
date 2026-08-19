//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension PushPreferenceLevel: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
}
