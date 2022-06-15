//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A parsed server response error.
public struct ErrorPayload: LocalizedError, Codable, CustomDebugStringConvertible, Equatable {
    private enum CodingKeys: String, CodingKey {
        case code
        case message
        case statusCode = "StatusCode"
        case details
    }
    
    /// An error code.
    public let code: Int
    /// A message.
    public let message: String
    /// An HTTP status code.
    public let statusCode: Int
    /// An array of specific details that compose the error.
    public let details: [ErrorPayloadDetail]
    
    public var errorDescription: String? {
        "Error #\(code): \(message)"
    }
    
    public var debugDescription: String {
        "ServerErrorPayload(code: \(code), message: \"\(message)\", statusCode: \(statusCode)))."
    }
}

extension ErrorPayload {
    /// Returns `true` if code is withing invalid token codes range.
    var isInvalidTokenError: Bool {
        ClosedRange.tokenInvalidErrorCodes ~= code
    }
    
    /// Returns `true` if status code is withing client error codes range.
    var isClientError: Bool {
        ClosedRange.clientErrorCodes ~= statusCode
    }
    
    /// Returns `true` if internal status code is related to a moderation bouncing error.
    var isBouncedError: Bool {
        code == 73
    }
}

extension ClosedRange where Bound == Int {
    /// The error codes for token-related errors. Typically, a refreshed token is required to recover.
    static let tokenInvalidErrorCodes: Self = 40...43
    
    /// The range of HTTP request status codes for client errors.
    static let clientErrorCodes: Self = 400...499
}

/// A parsed server response error detail.
public struct ErrorPayloadDetail: LocalizedError, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case code
        case messages
    }
    
    /// An error code.
    public let code: Int
    /// An array of  message strings that better describe the error detail.
    public let messages: [String]
}
