//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension PushPreferenceLevel: ExpressibleByStringLiteral {
    public convenience init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
}
