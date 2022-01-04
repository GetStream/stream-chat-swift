//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension Result {
    /// Get an error from the result if it failed.
    var error: Failure? {
        if case let .failure(error) = self {
            return error
        }

        return nil
    }
}
