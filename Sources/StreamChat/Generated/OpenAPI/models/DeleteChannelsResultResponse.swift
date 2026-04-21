//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DeleteChannelsResultResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var error: String?
    var status: String

    init(error: String? = nil, status: String) {
        self.error = error
        self.status = status
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case error
        case status
    }

    static func == (lhs: DeleteChannelsResultResponse, rhs: DeleteChannelsResultResponse) -> Bool {
        lhs.error == rhs.error &&
            lhs.status == rhs.status
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(error)
        hasher.combine(status)
    }
}
