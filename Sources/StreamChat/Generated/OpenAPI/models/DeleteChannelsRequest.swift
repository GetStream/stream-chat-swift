//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DeleteChannelsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// All channels that should be deleted
    var cids: [String]
    /// Specify if channels and all ressources should be hard deleted
    var hardDelete: Bool?

    init(cids: [String], hardDelete: Bool? = nil) {
        self.cids = cids
        self.hardDelete = hardDelete
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case cids
        case hardDelete = "hard_delete"
    }

    static func == (lhs: DeleteChannelsRequest, rhs: DeleteChannelsRequest) -> Bool {
        lhs.cids == rhs.cids &&
            lhs.hardDelete == rhs.hardDelete
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(cids)
        hasher.combine(hardDelete)
    }
}
