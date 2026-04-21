//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SubmitActionResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var appealItem: AppealItemResponse?
    var duration: String
    var item: ReviewQueueItemResponse?

    init(appealItem: AppealItemResponse? = nil, duration: String, item: ReviewQueueItemResponse? = nil) {
        self.appealItem = appealItem
        self.duration = duration
        self.item = item
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case appealItem = "appeal_item"
        case duration
        case item
    }

    static func == (lhs: SubmitActionResponse, rhs: SubmitActionResponse) -> Bool {
        lhs.appealItem == rhs.appealItem &&
            lhs.duration == rhs.duration &&
            lhs.item == rhs.item
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(appealItem)
        hasher.combine(duration)
        hasher.combine(item)
    }
}
