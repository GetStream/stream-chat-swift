//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGoLiveRequest: Codable, Hashable {
    public var startHls: Bool?
    
    public var startRecording: Bool?
    
    public var startTranscription: Bool?
    
    public init(startHls: Bool?, startRecording: Bool?, startTranscription: Bool?) {
        self.startHls = startHls
        
        self.startRecording = startRecording
        
        self.startTranscription = startTranscription
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case startHls = "start_hls"
        
        case startRecording = "start_recording"
        
        case startTranscription = "start_transcription"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(startHls, forKey: .startHls)
        
        try container.encode(startRecording, forKey: .startRecording)
        
        try container.encode(startTranscription, forKey: .startTranscription)
    }
}
