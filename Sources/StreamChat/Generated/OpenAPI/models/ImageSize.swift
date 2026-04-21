//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ImageSize: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Crop mode. One of: top, bottom, left, right, center
    var crop: String?
    /// Target image height
    var height: Int?
    /// Resize method. One of: clip, crop, scale, fill
    var resize: String?
    /// Target image width
    var width: Int?

    init(crop: String? = nil, height: Int? = nil, resize: String? = nil, width: Int? = nil) {
        self.crop = crop
        self.height = height
        self.resize = resize
        self.width = width
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case crop
        case height
        case resize
        case width
    }

    static func == (lhs: ImageSize, rhs: ImageSize) -> Bool {
        lhs.crop == rhs.crop &&
            lhs.height == rhs.height &&
            lhs.resize == rhs.resize &&
            lhs.width == rhs.width
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(crop)
        hasher.combine(height)
        hasher.combine(resize)
        hasher.combine(width)
    }
}
