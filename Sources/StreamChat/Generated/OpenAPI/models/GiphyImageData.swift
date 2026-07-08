//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GiphyImageData: Sendable, Codable, JSONEncodable {
    let frames: String
    let height: String
    let size: String
    let url: String
    let width: String

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
}

extension GiphyImageData: Hashable {
    static func == (lhs: GiphyImageData, rhs: GiphyImageData) -> Bool {
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
