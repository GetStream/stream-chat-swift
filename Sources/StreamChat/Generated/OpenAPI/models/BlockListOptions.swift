//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BlockListOptions: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum BlockListOptionsBehavior: String, Sendable, Codable, CaseIterable {
        case block
        case flag
        case shadowBlock = "shadow_block"
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

    /// Blocklist behavior. One of: flag, block, shadow_block
    var behavior: BlockListOptionsBehavior
    /// Blocklist name
    var blocklist: String

    init(behavior: BlockListOptionsBehavior, blocklist: String) {
        self.behavior = behavior
        self.blocklist = blocklist
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case behavior
        case blocklist
    }

    static func == (lhs: BlockListOptions, rhs: BlockListOptions) -> Bool {
        lhs.behavior == rhs.behavior &&
            lhs.blocklist == rhs.blocklist
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(behavior)
        hasher.combine(blocklist)
    }
}
