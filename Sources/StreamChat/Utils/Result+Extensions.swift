//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension Result {
    /// Get the value from the result if it succeeded.
    var value: Success? {
        if case let .success(value) = self {
            return value
        }

        return nil
    }

    /// Get an error from the result if it failed.
    var error: Failure? {
        if case let .failure(error) = self {
            return error
        }

        return nil
    }

    var isError: Bool {
        error != nil
    }
}
