//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchAllWarningCode: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    let rawValue: String

    var description: String { rawValue }

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    static let cursorRejected = SearchAllWarningCode(rawValue: "cursor_rejected")
}

final class SearchAllWarning: Sendable, Decodable {
    /// Warning code. cursor_rejected: the cursor supplied for this section failed to decode, so the section restarted from page 1
    let code: SearchAllWarningCode

    init(code: SearchAllWarningCode) {
        self.code = code
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.code = try container.decode(SearchAllWarningCode.self, forKey: .code)
    }
}
