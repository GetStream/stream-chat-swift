//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class TargetResolution: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var bitrate: Int
    var height: Int
    var width: Int

    init(bitrate: Int, height: Int, width: Int) {
        self.bitrate = bitrate
        self.height = height
        self.width = width
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case bitrate
        case height
        case width
    }

    static func == (lhs: TargetResolution, rhs: TargetResolution) -> Bool {
        lhs.bitrate == rhs.bitrate &&
            lhs.height == rhs.height &&
            lhs.width == rhs.width
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bitrate)
        hasher.combine(height)
        hasher.combine(width)
    }
}
