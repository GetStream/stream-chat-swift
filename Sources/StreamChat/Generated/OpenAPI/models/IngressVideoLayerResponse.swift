//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class IngressVideoLayerResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var bitrate: Int
    var codec: String
    var frameRateLimit: Int
    var maxDimension: Int
    var minDimension: Int

    init(bitrate: Int, codec: String, frameRateLimit: Int, maxDimension: Int, minDimension: Int) {
        self.bitrate = bitrate
        self.codec = codec
        self.frameRateLimit = frameRateLimit
        self.maxDimension = maxDimension
        self.minDimension = minDimension
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case bitrate
        case codec
        case frameRateLimit = "frame_rate_limit"
        case maxDimension = "max_dimension"
        case minDimension = "min_dimension"
    }

    static func == (lhs: IngressVideoLayerResponse, rhs: IngressVideoLayerResponse) -> Bool {
        lhs.bitrate == rhs.bitrate &&
            lhs.codec == rhs.codec &&
            lhs.frameRateLimit == rhs.frameRateLimit &&
            lhs.maxDimension == rhs.maxDimension &&
            lhs.minDimension == rhs.minDimension
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bitrate)
        hasher.combine(codec)
        hasher.combine(frameRateLimit)
        hasher.combine(maxDimension)
        hasher.combine(minDimension)
    }
}
