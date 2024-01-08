//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatDeleteChannelsResponse: Codable, Hashable {
    public var duration: String
    
    public var result: [String: RawJSON]?
    
    public var taskId: String?
    
    public init(duration: String, result: [String: RawJSON]?, taskId: String?) {
        self.duration = duration
        
        self.result = result
        
        self.taskId = taskId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case result
        
        case taskId = "task_id"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(result, forKey: .result)
        
        try container.encode(taskId, forKey: .taskId)
    }
}
