//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A parsed server response error.
public struct ErrorPayload: LocalizedError, Codable, CustomDebugStringConvertible, Equatable {
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

/// https://getstream.io/chat/docs/ios-swift/api_errors_response/
private enum StreamErrorCode {
    /// Usually returned when trying to perform an API call without a token.
    static let accessKeyInvalid = 2
    static let expiredToken = 40
    static let notYetValidToken = 41
    static let invalidTokenDate = 42
    static let invalidTokenSignature = 43
}

extension ErrorPayload {
    /// Returns `true` if the code determines that the token is expired.
    var isExpiredTokenError: Bool {
        code == StreamErrorCode.expiredToken
    }

    /// Returns `true` if code is within invalid token codes range.
    var isInvalidTokenError: Bool {
        ClosedRange.tokenInvalidErrorCodes ~= code || code == StreamErrorCode.accessKeyInvalid
    }

    /// Returns `true` if status code is within client error codes range.
    var isClientError: Bool {
        ClosedRange.clientErrorCodes ~= statusCode
    }
}

extension ClosedRange where Bound == Int {
    /// The error codes for token-related errors. Typically, a refreshed token is required to recover.
    static let tokenInvalidErrorCodes: Self = StreamErrorCode.expiredToken...StreamErrorCode.invalidTokenSignature

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
