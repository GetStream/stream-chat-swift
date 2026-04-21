//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DeleteChannelsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    /// Map of channel IDs and their deletion results
    var result: [String: DeleteChannelsResultResponse?]?
    var taskId: String?

    init(duration: String, result: [String: DeleteChannelsResultResponse?]? = nil, taskId: String? = nil) {
        self.duration = duration
        self.result = result
        self.taskId = taskId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case result
        case taskId = "task_id"
    }

    static func == (lhs: DeleteChannelsResponse, rhs: DeleteChannelsResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.result == rhs.result &&
            lhs.taskId == rhs.taskId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(result)
        hasher.combine(taskId)
    }
}
