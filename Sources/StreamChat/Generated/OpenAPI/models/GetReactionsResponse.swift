//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetReactionsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var duration: String
    /// List of reactions
    var reactions: [ReactionResponse]

    init(duration: String, reactions: [ReactionResponse]) {
        self.duration = duration
        self.reactions = reactions
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case reactions
    }

    static func == (lhs: GetReactionsResponse, rhs: GetReactionsResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.reactions == rhs.reactions
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(reactions)
    }
}
