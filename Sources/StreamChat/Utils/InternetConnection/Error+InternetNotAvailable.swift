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
        let engineError = (self as? WebSocketEngineError)?.engineError
        return offlineErrors.contains {
            self.has(parameters: $0) || (engineError?.has(parameters: $0) ?? false)
        }
    }
    
    private func has(parameters: (domain: String, errorCode: Int)) -> Bool {
        let error = self as NSError
        return error.domain == parameters.domain && error.code == parameters.errorCode
    }
    
    var isBackendErrorWith400StatusCode: Bool {
        if let error = (self as? ClientError)?.underlyingError as? ErrorPayload,
           error.statusCode == 400 {
            return true
        }
        return false
    }
    
    var isRateLimitError: Bool {
        if let error = (self as? ClientError)?.underlyingError as? ErrorPayload,
           error.statusCode == 429 {
            return true
        }
        return false
    }
}
