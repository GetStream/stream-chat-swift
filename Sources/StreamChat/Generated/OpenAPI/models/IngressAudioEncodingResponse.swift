//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class IngressAudioEncodingResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var bitrate: Int
    var channels: Int
    var enableDtx: Bool

    init(bitrate: Int, channels: Int, enableDtx: Bool) {
        self.bitrate = bitrate
        self.channels = channels
        self.enableDtx = enableDtx
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case bitrate
        case channels
        case enableDtx = "enable_dtx"
    }

    static func == (lhs: IngressAudioEncodingResponse, rhs: IngressAudioEncodingResponse) -> Bool {
        lhs.bitrate == rhs.bitrate &&
            lhs.channels == rhs.channels &&
            lhs.enableDtx == rhs.enableDtx
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bitrate)
        hasher.combine(channels)
        hasher.combine(enableDtx)
    }
}
