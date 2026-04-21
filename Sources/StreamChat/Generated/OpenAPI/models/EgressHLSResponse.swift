//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class EgressHLSResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var playlistUrl: String
    var status: String

    init(playlistUrl: String, status: String) {
        self.playlistUrl = playlistUrl
        self.status = status
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case playlistUrl = "playlist_url"
        case status
    }

    static func == (lhs: EgressHLSResponse, rhs: EgressHLSResponse) -> Bool {
        lhs.playlistUrl == rhs.playlistUrl &&
            lhs.status == rhs.status
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(playlistUrl)
        hasher.combine(status)
    }
}
