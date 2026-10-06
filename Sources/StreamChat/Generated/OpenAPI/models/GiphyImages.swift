//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GiphyImages: Sendable, Codable, JSONEncodable {
    let fixedHeight: GiphyImageData
    let fixedHeightDownsampled: GiphyImageData
    let fixedHeightStill: GiphyImageData
    let fixedWidth: GiphyImageData
    let fixedWidthDownsampled: GiphyImageData
    let fixedWidthStill: GiphyImageData
    let original: GiphyImageData

    init(
        fixedHeight: GiphyImageData,
        fixedHeightDownsampled: GiphyImageData,
        fixedHeightStill: GiphyImageData,
        fixedWidth: GiphyImageData,
        fixedWidthDownsampled: GiphyImageData,
        fixedWidthStill: GiphyImageData,
        original: GiphyImageData
    ) {
        self.fixedHeight = fixedHeight
        self.fixedHeightDownsampled = fixedHeightDownsampled
        self.fixedHeightStill = fixedHeightStill
        self.fixedWidth = fixedWidth
        self.fixedWidthDownsampled = fixedWidthDownsampled
        self.fixedWidthStill = fixedWidthStill
        self.original = original
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.fixedHeight = try container.decode(GiphyImageData.self, forKey: .fixedHeight)
        self.fixedHeightDownsampled = try container.decode(
            GiphyImageData.self,
            forKey: .fixedHeightDownsampled
        )
        self.fixedHeightStill = try container.decode(GiphyImageData.self, forKey: .fixedHeightStill)
        self.fixedWidth = try container.decode(GiphyImageData.self, forKey: .fixedWidth)
        self.fixedWidthDownsampled = try container.decode(
            GiphyImageData.self,
            forKey: .fixedWidthDownsampled
        )
        self.fixedWidthStill = try container.decode(GiphyImageData.self, forKey: .fixedWidthStill)
        self.original = try container.decode(GiphyImageData.self, forKey: .original)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(fixedHeight, forKey: .fixedHeight)
        try container.encode(fixedHeightDownsampled, forKey: .fixedHeightDownsampled)
        try container.encode(fixedHeightStill, forKey: .fixedHeightStill)
        try container.encode(fixedWidth, forKey: .fixedWidth)
        try container.encode(fixedWidthDownsampled, forKey: .fixedWidthDownsampled)
        try container.encode(fixedWidthStill, forKey: .fixedWidthStill)
        try container.encode(original, forKey: .original)
    }
}
