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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.frames = try container.decode(String.self, forKey: .frames)
        self.height = try container.decode(String.self, forKey: .height)
        self.size = try container.decode(String.self, forKey: .size)
        self.url = try container.decode(String.self, forKey: .url)
        self.width = try container.decode(String.self, forKey: .width)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(frames, forKey: .frames)
        try container.encode(height, forKey: .height)
        try container.encode(size, forKey: .size)
        try container.encode(url, forKey: .url)
        try container.encode(width, forKey: .width)
    }
}
