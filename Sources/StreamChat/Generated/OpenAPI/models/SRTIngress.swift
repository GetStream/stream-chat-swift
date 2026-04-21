//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SRTIngress: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var address: String

    init(address: String) {
        self.address = address
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case address
    }

    static func == (lhs: SRTIngress, rhs: SRTIngress) -> Bool {
        lhs.address == rhs.address
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }
}
