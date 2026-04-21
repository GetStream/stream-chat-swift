//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class IngressSourceResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var fps: Int
    var height: Int
    var width: Int

    init(fps: Int, height: Int, width: Int) {
        self.fps = fps
        self.height = height
        self.width = width
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case fps
        case height
        case width
    }

    static func == (lhs: IngressSourceResponse, rhs: IngressSourceResponse) -> Bool {
        lhs.fps == rhs.fps &&
            lhs.height == rhs.height &&
            lhs.width == rhs.width
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(fps)
        hasher.combine(height)
        hasher.combine(width)
    }
}
