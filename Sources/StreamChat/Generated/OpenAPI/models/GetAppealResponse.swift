//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetAppealResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var duration: String
    var item: AppealItemResponse?

    init(duration: String, item: AppealItemResponse? = nil) {
        self.duration = duration
        self.item = item
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case item
    }

    static func == (lhs: GetAppealResponse, rhs: GetAppealResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.item == rhs.item
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(item)
    }
}
