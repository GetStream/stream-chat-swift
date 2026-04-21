//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class APIError: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// API error code
    var code: Int
    /// Additional error-specific information
    var details: [Int]
    /// Request duration
    var duration: String
    /// Additional error info
    var exceptionFields: [String: String]?
    /// Message describing an error
    var message: String
    /// URL with additional information
    var moreInfo: String
    /// Response HTTP status code
    var statusCode: Int
    /// Flag that indicates if the error is unrecoverable, requests that return unrecoverable errors should not be retried, this error only applies to the request that caused it
    var unrecoverable: Bool?

    init(code: Int, details: [Int], duration: String, exceptionFields: [String: String]? = nil, message: String, moreInfo: String, statusCode: Int, unrecoverable: Bool? = nil) {
        self.code = code
        self.details = details
        self.duration = duration
        self.exceptionFields = exceptionFields
        self.message = message
        self.moreInfo = moreInfo
        self.statusCode = statusCode
        self.unrecoverable = unrecoverable
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case code
        case details
        case duration
        case exceptionFields = "exception_fields"
        case message
        case moreInfo = "more_info"
        case statusCode = "StatusCode"
        case unrecoverable
    }

    static func == (lhs: APIError, rhs: APIError) -> Bool {
        lhs.code == rhs.code &&
            lhs.details == rhs.details &&
            lhs.duration == rhs.duration &&
            lhs.exceptionFields == rhs.exceptionFields &&
            lhs.message == rhs.message &&
            lhs.moreInfo == rhs.moreInfo &&
            lhs.statusCode == rhs.statusCode &&
            lhs.unrecoverable == rhs.unrecoverable
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
        hasher.combine(details)
        hasher.combine(duration)
        hasher.combine(exceptionFields)
        hasher.combine(message)
        hasher.combine(moreInfo)
        hasher.combine(statusCode)
        hasher.combine(unrecoverable)
    }
}
