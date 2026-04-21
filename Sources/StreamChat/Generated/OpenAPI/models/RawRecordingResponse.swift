//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class RawRecordingResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var status: String

    init(status: String) {
        self.status = status
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case status
    }

    static func == (lhs: RawRecordingResponse, rhs: RawRecordingResponse) -> Bool {
        lhs.status == rhs.status
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(status)
    }
}
