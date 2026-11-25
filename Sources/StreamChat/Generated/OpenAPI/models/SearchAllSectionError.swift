//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchAllSectionErrorCode: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    let rawValue: String

    var description: String { rawValue }

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    static let backendTimeout = SearchAllSectionErrorCode(rawValue: "backend_timeout")
    static let backendUnavailable = SearchAllSectionErrorCode(rawValue: "backend_unavailable")
    static let internalError = SearchAllSectionErrorCode(rawValue: "internal_error")
    static let unsupported = SearchAllSectionErrorCode(rawValue: "unsupported")
}

final class SearchAllSectionError: Sendable, Decodable {
    /// Error code. backend_timeout and backend_unavailable are retryable; unsupported (the app's configuration cannot serve this section) and internal_error are not
    let code: SearchAllSectionErrorCode
    /// Human-readable description of the failure
    let message: String

    init(code: SearchAllSectionErrorCode, message: String) {
        self.code = code
        self.message = message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.code = try container.decode(SearchAllSectionErrorCode.self, forKey: .code)
        self.message = try container.decode(String.self, forKey: .message)
    }
}
