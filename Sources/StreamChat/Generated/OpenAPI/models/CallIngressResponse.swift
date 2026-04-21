//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CallIngressResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var rtmp: RTMPIngress
    var srt: SRTIngress
    var whip: WHIPIngress

    init(rtmp: RTMPIngress, srt: SRTIngress, whip: WHIPIngress) {
        self.rtmp = rtmp
        self.srt = srt
        self.whip = whip
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case rtmp
        case srt
        case whip
    }

    static func == (lhs: CallIngressResponse, rhs: CallIngressResponse) -> Bool {
        lhs.rtmp == rhs.rtmp &&
            lhs.srt == rhs.srt &&
            lhs.whip == rhs.whip
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(rtmp)
        hasher.combine(srt)
        hasher.combine(whip)
    }
}
