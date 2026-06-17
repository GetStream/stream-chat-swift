//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ImageData: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var frames: String
    var height: String
    var size: String
    var url: String
    var width: String

    init(frames: String, height: String, size: String, url: String, width: String) {
        self.frames = frames
        self.height = height
        self.size = size
        self.url = url
        self.width = width
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case frames
        case height
        case size
        case url
        case width
    }

    static func == (lhs: ImageData, rhs: ImageData) -> Bool {
        lhs.frames == rhs.frames &&
            lhs.height == rhs.height &&
            lhs.size == rhs.size &&
            lhs.url == rhs.url &&
            lhs.width == rhs.width
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(frames)
        hasher.combine(height)
        hasher.combine(size)
        hasher.combine(url)
        hasher.combine(width)
    }
}
