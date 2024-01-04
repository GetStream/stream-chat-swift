//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallRecording: Codable, Hashable {
    public var endTime: String
    
    public var filename: String
    
    public var startTime: String
    
    public var url: String
    
    public init(endTime: String, filename: String, startTime: String, url: String) {
        self.endTime = endTime
        
        self.filename = filename
        
        self.startTime = startTime
        
        self.url = url
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case endTime = "end_time"
        
        case filename
        
        case startTime = "start_time"
        
        case url
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(endTime, forKey: .endTime)
        
        try container.encode(filename, forKey: .filename)
        
        try container.encode(startTime, forKey: .startTime)
        
        try container.encode(url, forKey: .url)
    }
}
