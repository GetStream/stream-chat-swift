//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct DeleteChannelsResponse: Codable, Hashable {
    public var duration: String
    public var taskId: String? = nil
    public var result: [String: DeleteChannelsResult?]? = nil

    public init(duration: String, taskId: String? = nil, result: [String: DeleteChannelsResult?]? = nil) {
        self.duration = duration
        self.taskId = taskId
        self.result = result
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case taskId = "task_id"
        case result
    }
}
