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

    init(
        frames: String,
        height: String,
        size: String,
        url: String,
        width: String
    ) {
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
