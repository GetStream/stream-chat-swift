//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 17.0, macOS 14.0, *)
enum NumberFormatting {
    static func decimal(_ value: Double) -> String {
        guard value.isFinite else { return JS.numberToString(value) }
        return value.formatted(.number.precision(.fractionLength(0...6)))
    }

    static func integer(_ value: Int) -> String {
        value.formatted(.number)
    }

    static func percent(_ value: Double) -> String {
        guard value.isFinite else { return JS.numberToString(value) + "%" }
        return (value / 100).formatted(.percent.precision(.fractionLength(0...2)))
    }
}
