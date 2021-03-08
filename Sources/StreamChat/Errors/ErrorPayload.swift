//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A parsed server response error.
struct ErrorPayload: LocalizedError, Codable, CustomDebugStringConvertible, Equatable {
    /// The error codes for token-related errors. Typically, a refreshed token is required to recover.
    static let tokenInvadlidErrorCodes = 40...43
    
    private enum CodingKeys: String, CodingKey {
        case code
        case message
        case statusCode = "StatusCode"
    }
    
    /// An error code.
    public let code: Int
    /// A message.
    public let message: String
    /// An HTTP status code.
    public let statusCode: Int
    
    public var errorDescription: String? {
        "Error #\(code): \(message)"
    }
    
    public var debugDescription: String {
        "ServerErrorPayload(code: \(code), message: \"\(message)\", statusCode: \(statusCode)))."
    }
}
