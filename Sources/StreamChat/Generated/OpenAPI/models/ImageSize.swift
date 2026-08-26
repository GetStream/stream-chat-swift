//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ImageSize: Sendable, Codable, JSONEncodable {
    /// Crop mode. One of: top, bottom, left, right, center
    let crop: String?
    /// Target image height
    let height: Int?
    /// Resize method. One of: clip, crop, scale, fill
    let resize: String?
    /// Target image width
    let width: Int?

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
}
