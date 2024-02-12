//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ImageSizeRequest: Codable, Hashable {
    public var crop: String? = nil
    public var height: Int? = nil
    public var resize: String? = nil
    public var width: Int? = nil

    public init(crop: String? = nil, height: Int? = nil, resize: String? = nil, width: Int? = nil) {
        self.crop = crop
        self.height = height
        self.resize = resize
        self.width = width
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case crop
        case height
        case resize
        case width
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(crop, forKey: .crop)
        try container.encode(height, forKey: .height)
        try container.encode(resize, forKey: .resize)
        try container.encode(width, forKey: .width)
    }
}
