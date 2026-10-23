//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamCore

public extension String {
    /// Converts a string to `Date`. Only for testing!
    func toDate() -> Date {
        RFC3339DateFormatter.date(from: self)!
    }
}
