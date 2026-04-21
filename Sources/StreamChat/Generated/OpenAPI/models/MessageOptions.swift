//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageOptions: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var includeThreadParticipants: Bool?

    init(includeThreadParticipants: Bool? = nil) {
        self.includeThreadParticipants = includeThreadParticipants
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case includeThreadParticipants = "include_thread_participants"
    }

    static func == (lhs: MessageOptions, rhs: MessageOptions) -> Bool {
        lhs.includeThreadParticipants == rhs.includeThreadParticipants
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(includeThreadParticipants)
    }
}
