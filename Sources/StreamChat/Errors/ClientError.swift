//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension ClientError {
    /// Returns `true` the stream code determines that the token is expired.
    var isExpiredTokenError: Bool {
        (underlyingError as? ErrorPayload)?.isExpiredTokenError == true
    }

    /// The error payload if the underlying error comes from a server error.
    public var errorPayload: ErrorPayload? { underlyingError as? ErrorPayload }
}
