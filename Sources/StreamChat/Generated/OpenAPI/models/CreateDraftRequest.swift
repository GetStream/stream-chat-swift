//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreateDraftRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var message: MessageRequest

    init(message: MessageRequest) {
        self.message = message
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case message
    }

    static func == (lhs: CreateDraftRequest, rhs: CreateDraftRequest) -> Bool {
        lhs.message == rhs.message
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(message)
    }
}
