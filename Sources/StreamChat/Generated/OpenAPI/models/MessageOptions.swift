//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageOptions: Sendable, Encodable, JSONEncodable {
    let includeThreadParticipants: Bool?
    let memberCustomInclude: [String]?

    init(includeThreadParticipants: Bool? = nil, memberCustomInclude: [String]? = nil) {
        self.includeThreadParticipants = includeThreadParticipants
        self.memberCustomInclude = memberCustomInclude
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case includeThreadParticipants = "include_thread_participants"
        case memberCustomInclude = "member_custom_include"
    }
}
