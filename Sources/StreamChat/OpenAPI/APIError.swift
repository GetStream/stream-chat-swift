//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension APIError: Error {}

public struct APIError: Codable, Hashable {
    /** Response HTTP status code */
    public var statusCode: Int
    /** API error code */
    public var code: Int
    /** Additional error-specific information */
    public var details: [Int]
    /** Request duration */
    public var duration: String
    /** Additional error info */
    public var exceptionFields: [String: String]?
    /** Message describing an error */
    public var message: String
    /** URL with additional information */
    public var moreInfo: String

    public init(statusCode: Int, code: Int, details: [Int], duration: String, exceptionFields: [String: String]? = nil, message: String, moreInfo: String) {
        self.statusCode = statusCode
        self.code = code
        self.details = details
        self.duration = duration
        self.exceptionFields = exceptionFields
        self.message = message
        self.moreInfo = moreInfo
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case statusCode = "StatusCode"
        case code
        case details
        case duration
        case exceptionFields = "exception_fields"
        case message
        case moreInfo = "more_info"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(statusCode, forKey: .statusCode)
        try container.encode(code, forKey: .code)
        try container.encode(details, forKey: .details)
        try container.encode(duration, forKey: .duration)
        try container.encodeIfPresent(exceptionFields, forKey: .exceptionFields)
        try container.encode(message, forKey: .message)
        try container.encode(moreInfo, forKey: .moreInfo)
    }
}
