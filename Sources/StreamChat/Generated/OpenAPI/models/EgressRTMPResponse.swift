//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class EgressRTMPResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var name: String
    var startedAt: Timestamp
    var streamKey: String?
    var streamUrl: String?

    init(name: String, startedAt: Timestamp, streamKey: String? = nil, streamUrl: String? = nil) {
        self.name = name
        self.startedAt = startedAt
        self.streamKey = streamKey
        self.streamUrl = streamUrl
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        case startedAt = "started_at"
        case streamKey = "stream_key"
        case streamUrl = "stream_url"
    }

    static func == (lhs: EgressRTMPResponse, rhs: EgressRTMPResponse) -> Bool {
        lhs.name == rhs.name &&
            lhs.startedAt == rhs.startedAt &&
            lhs.streamKey == rhs.streamKey &&
            lhs.streamUrl == rhs.streamUrl
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(startedAt)
        hasher.combine(streamKey)
        hasher.combine(streamUrl)
    }
}
