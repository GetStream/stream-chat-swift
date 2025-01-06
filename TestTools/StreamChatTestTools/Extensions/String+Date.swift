//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension String {
    /// Converts a string to `Date`. Only for testing!
    func toDate() -> Date {
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
        if let date = iso8601Formatter.dateWithMicroseconds(from: self) {
            return date
        }
        return DateFormatter.Stream.rfc3339Date(from: self)!
    }
}
