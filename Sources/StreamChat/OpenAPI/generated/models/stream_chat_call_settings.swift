//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallSettings: Codable, Hashable {
    public var audio: StreamChatAudioSettings?
    
    public var geofencing: StreamChatGeofenceSettings?
    
    public var ring: StreamChatRingSettings?
    
    public var transcription: StreamChatTranscriptionSettings?
    
    public var video: StreamChatVideoSettings?
    
    public var backstage: StreamChatBackstageSettings?
    
    public var broadcasting: StreamChatBroadcastSettings?
    
    public var recording: StreamChatRecordSettings?
    
    public var screensharing: StreamChatScreensharingSettings?
    
    public var thumbnails: StreamChatThumbnailsSettings?
    
    public init(audio: StreamChatAudioSettings?, geofencing: StreamChatGeofenceSettings?, ring: StreamChatRingSettings?, transcription: StreamChatTranscriptionSettings?, video: StreamChatVideoSettings?, backstage: StreamChatBackstageSettings?, broadcasting: StreamChatBroadcastSettings?, recording: StreamChatRecordSettings?, screensharing: StreamChatScreensharingSettings?, thumbnails: StreamChatThumbnailsSettings?) {
        self.audio = audio
        
        self.geofencing = geofencing
        
        self.ring = ring
        
        self.transcription = transcription
        
        self.video = video
        
        self.backstage = backstage
        
        self.broadcasting = broadcasting
        
        self.recording = recording
        
        self.screensharing = screensharing
        
        self.thumbnails = thumbnails
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case audio
        
        case geofencing
        
        case ring
        
        case transcription
        
        case video
        
        case backstage
        
        case broadcasting
        
        case recording
        
        case screensharing
        
        case thumbnails
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(audio, forKey: .audio)
        
        try container.encode(geofencing, forKey: .geofencing)
        
        try container.encode(ring, forKey: .ring)
        
        try container.encode(transcription, forKey: .transcription)
        
        try container.encode(video, forKey: .video)
        
        try container.encode(backstage, forKey: .backstage)
        
        try container.encode(broadcasting, forKey: .broadcasting)
        
        try container.encode(recording, forKey: .recording)
        
        try container.encode(screensharing, forKey: .screensharing)
        
        try container.encode(thumbnails, forKey: .thumbnails)
    }
}
