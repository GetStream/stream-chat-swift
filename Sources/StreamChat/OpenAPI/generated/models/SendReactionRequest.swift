//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct SendReactionRequest: Codable, Hashable {
    public var reaction: ReactionRequest
    public var enforceUnique: Bool? = nil
    public var iD: String? = nil
    public var skipPush: Bool? = nil

    public init(reaction: ReactionRequest, enforceUnique: Bool? = nil, iD: String? = nil, skipPush: Bool? = nil) {
        self.reaction = reaction
        self.enforceUnique = enforceUnique
        self.iD = iD
        self.skipPush = skipPush
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reaction
        case enforceUnique = "enforce_unique"
        case iD = "ID"
        case skipPush = "skip_push"
    }
}
