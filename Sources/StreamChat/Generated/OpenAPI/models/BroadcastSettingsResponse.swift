//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BroadcastSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var enabled: Bool
    var hls: HLSSettingsResponse
    var rtmp: RTMPSettingsResponse

    init(enabled: Bool, hls: HLSSettingsResponse, rtmp: RTMPSettingsResponse) {
        self.enabled = enabled
        self.hls = hls
        self.rtmp = rtmp
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case hls
        case rtmp
    }

    static func == (lhs: BroadcastSettingsResponse, rhs: BroadcastSettingsResponse) -> Bool {
        lhs.enabled == rhs.enabled &&
            lhs.hls == rhs.hls &&
            lhs.rtmp == rhs.rtmp
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
        hasher.combine(hls)
        hasher.combine(rtmp)
    }
}
