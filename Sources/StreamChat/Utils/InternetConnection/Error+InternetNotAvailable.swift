//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The list of know n"internet connection is not available" errors. This list is hardly completely and it's meant
/// to be extended as needed.
private let offlineErrors: [(domain: String, errorCode: Int)] = [
    (NSURLErrorDomain, NSURLErrorNotConnectedToInternet),
    (NSPOSIXErrorDomain, 50)
]

extension Error {
    /// Returns `true` if the error is one of the known errors for internet connection not being available.
    var isInternetOfflineError: Bool {
        let error = self as NSError
        return offlineErrors.contains { $0.domain == error.domain && $0.errorCode == error.code }
    }
}
