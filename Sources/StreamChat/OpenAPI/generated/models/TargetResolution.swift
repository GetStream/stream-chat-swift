//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct TargetResolution: Codable, Hashable {
    public var bitrate: Int
    public var height: Int
    public var width: Int

    public init(bitrate: Int, height: Int, width: Int) {
        self.bitrate = bitrate
        self.height = height
        self.width = width
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case bitrate
        case height
        case width
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bitrate, forKey: .bitrate)
        try container.encode(height, forKey: .height)
        try container.encode(width, forKey: .width)
    }
}
