//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension String {
    /// Converst a string to `Date`. Only for testing!
    func toDate() -> Date {
        if let date = JSONDecoder.stream.iso8601formatter.dateWithMicroseconds(from: self) {
            return date
        }
        return DateFormatter.Stream.rfc3339Date(from: self)!
    }
}
