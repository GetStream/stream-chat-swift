//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CustomActionRequestPayload: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Custom action identifier
    var id: String?
    /// Custom action options
    var options: [String: RawJSON]?

    init(id: String? = nil, options: [String: RawJSON]? = nil) {
        self.id = id
        self.options = options
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case options
    }

    static func == (lhs: CustomActionRequestPayload, rhs: CustomActionRequestPayload) -> Bool {
        lhs.id == rhs.id &&
            lhs.options == rhs.options
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(options)
    }
}
