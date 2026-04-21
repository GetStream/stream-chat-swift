//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SendReactionResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var message: MessageResponse
    var reaction: ReactionResponse

    init(duration: String, message: MessageResponse, reaction: ReactionResponse) {
        self.duration = duration
        self.message = message
        self.reaction = reaction
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case message
        case reaction
    }

    static func == (lhs: SendReactionResponse, rhs: SendReactionResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.message == rhs.message &&
            lhs.reaction == rhs.reaction
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(message)
        hasher.combine(reaction)
    }
}
