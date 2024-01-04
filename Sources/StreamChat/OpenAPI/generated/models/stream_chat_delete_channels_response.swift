//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatDeleteChannelsResponse: Codable, Hashable {
    public var taskId: String?
    
    public var duration: String
    
    public var result: [String: RawJSON]?
    
    public init(taskId: String?, duration: String, result: [String: RawJSON]?) {
        self.taskId = taskId
        
        self.duration = duration
        
        self.result = result
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case taskId = "task_id"
        
        case duration
        
        case result
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(taskId, forKey: .taskId)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(result, forKey: .result)
    }
}
