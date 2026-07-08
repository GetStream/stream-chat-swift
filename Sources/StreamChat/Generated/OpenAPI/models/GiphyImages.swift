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

    init(fixedHeight: GiphyImageData, fixedHeightDownsampled: GiphyImageData, fixedHeightStill: GiphyImageData, fixedWidth: GiphyImageData, fixedWidthDownsampled: GiphyImageData, fixedWidthStill: GiphyImageData, original: GiphyImageData) {
        self.fixedHeight = fixedHeight
        self.fixedHeightDownsampled = fixedHeightDownsampled
        self.fixedHeightStill = fixedHeightStill
        self.fixedWidth = fixedWidth
        self.fixedWidthDownsampled = fixedWidthDownsampled
        self.fixedWidthStill = fixedWidthStill
        self.original = original
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case fixedHeight = "fixed_height"
        case fixedHeightDownsampled = "fixed_height_downsampled"
        case fixedHeightStill = "fixed_height_still"
        case fixedWidth = "fixed_width"
        case fixedWidthDownsampled = "fixed_width_downsampled"
        case fixedWidthStill = "fixed_width_still"
        case original
    }
}

extension GiphyImages: Hashable {
    static func == (lhs: GiphyImages, rhs: GiphyImages) -> Bool {
        lhs.fixedHeight == rhs.fixedHeight &&
            lhs.fixedHeightDownsampled == rhs.fixedHeightDownsampled &&
            lhs.fixedHeightStill == rhs.fixedHeightStill &&
            lhs.fixedWidth == rhs.fixedWidth &&
            lhs.fixedWidthDownsampled == rhs.fixedWidthDownsampled &&
            lhs.fixedWidthStill == rhs.fixedWidthStill &&
            lhs.original == rhs.original
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(fixedHeight)
        hasher.combine(fixedHeightDownsampled)
        hasher.combine(fixedHeightStill)
        hasher.combine(fixedWidth)
        hasher.combine(fixedWidthDownsampled)
        hasher.combine(fixedWidthStill)
        hasher.combine(original)
    }
}
