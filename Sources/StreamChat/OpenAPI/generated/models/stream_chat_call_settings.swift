//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallSettings: Codable, Hashable {
    public var audio: StreamChatAudioSettings? = nil
    
    public var backstage: StreamChatBackstageSettings? = nil
    
    public var broadcasting: StreamChatBroadcastSettings? = nil
    
    public var geofencing: StreamChatGeofenceSettings? = nil
    
    public var recording: StreamChatRecordSettings? = nil
    
    public var ring: StreamChatRingSettings? = nil
    
    public var screensharing: StreamChatScreensharingSettings? = nil
    
    public var thumbnails: StreamChatThumbnailsSettings? = nil
    
    public var transcription: StreamChatTranscriptionSettings? = nil
    
    public var video: StreamChatVideoSettings? = nil
    
    public init(audio: StreamChatAudioSettings? = nil, backstage: StreamChatBackstageSettings? = nil, broadcasting: StreamChatBroadcastSettings? = nil, geofencing: StreamChatGeofenceSettings? = nil, recording: StreamChatRecordSettings? = nil, ring: StreamChatRingSettings? = nil, screensharing: StreamChatScreensharingSettings? = nil, thumbnails: StreamChatThumbnailsSettings? = nil, transcription: StreamChatTranscriptionSettings? = nil, video: StreamChatVideoSettings? = nil) {
        self.audio = audio
        
        self.backstage = backstage
        
        self.broadcasting = broadcasting
        
        self.geofencing = geofencing
        
        self.recording = recording
        
        self.ring = ring
        
        self.screensharing = screensharing
        
        self.thumbnails = thumbnails
        
        self.transcription = transcription
        
        self.video = video
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case audio
        
        case backstage
        
        case broadcasting
        
        case geofencing
        
        case recording
        
        case ring
        
        case screensharing
        
        case thumbnails
        
        case transcription
        
        case video
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(audio, forKey: .audio)
        
        try container.encode(backstage, forKey: .backstage)
        
        try container.encode(broadcasting, forKey: .broadcasting)
        
        try container.encode(geofencing, forKey: .geofencing)
        
        try container.encode(recording, forKey: .recording)
        
        try container.encode(ring, forKey: .ring)
        
        try container.encode(screensharing, forKey: .screensharing)
        
        try container.encode(thumbnails, forKey: .thumbnails)
        
        try container.encode(transcription, forKey: .transcription)
        
        try container.encode(video, forKey: .video)
    }
}
