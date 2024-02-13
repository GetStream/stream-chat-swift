//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ImageSize: Codable, Hashable {
    public var crop: String
    public var height: Int
    public var resize: String
    public var width: Int

    public init(crop: String, height: Int, resize: String, width: Int) {
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
}
