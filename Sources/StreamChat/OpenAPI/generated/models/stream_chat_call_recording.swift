//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallRecording: Codable, Hashable {
    public var url: String
    
    public var endTime: Date
    
    public var filename: String
    
    public var startTime: Date
    
    public init(url: String, endTime: Date, filename: String, startTime: Date) {
        self.url = url
        
        self.endTime = endTime
        
        self.filename = filename
        
        self.startTime = startTime
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case url
        
        case endTime = "end_time"
        
        case filename
        
        case startTime = "start_time"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(url, forKey: .url)
        
        try container.encode(endTime, forKey: .endTime)
        
        try container.encode(filename, forKey: .filename)
        
        try container.encode(startTime, forKey: .startTime)
    }
}
