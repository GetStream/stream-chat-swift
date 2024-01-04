//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatListRecordingsResponse: Codable, Hashable {
    public var duration: String
    
    public var recordings: [StreamChatCallRecording]
    
    public init(duration: String, recordings: [StreamChatCallRecording]) {
        self.duration = duration
        
        self.recordings = recordings
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case recordings
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(recordings, forKey: .recordings)
    }
}
