//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct SendReactionResponse: Codable, Hashable {
    public var duration: String
    public var message: MessageResponse
    public var reaction: ReactionResponse

    public init(duration: String, message: MessageResponse, reaction: ReactionResponse) {
        self.duration = duration
        self.message = message
        self.reaction = reaction
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case message
        case reaction
    }
}
