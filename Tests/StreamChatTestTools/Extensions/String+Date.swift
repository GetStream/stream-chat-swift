//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension String {
    /// Converst a string to `Date`. Only for testing!
    func toDate() -> Date {
        DateFormatter.Stream.rfc3339Date(from: self)!
    }
}
