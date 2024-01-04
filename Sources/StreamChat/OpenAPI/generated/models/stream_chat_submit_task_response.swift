//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSubmitTaskResponse: Codable, Hashable {
    public var duration: String
    
    public var task: StreamChatTaskResponse
    
    public init(duration: String, task: StreamChatTaskResponse) {
        self.duration = duration
        
        self.task = task
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case task
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(task, forKey: .task)
    }
}
