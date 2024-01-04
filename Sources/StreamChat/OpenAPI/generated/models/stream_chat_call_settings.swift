//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallSettings: Codable, Hashable {
    public var geofencing: StreamChatGeofenceSettings?
    
    public var recording: StreamChatRecordSettings?
    
    public var ring: StreamChatRingSettings?
    
    public var thumbnails: StreamChatThumbnailsSettings?
    
    public var video: StreamChatVideoSettings?
    
    public var audio: StreamChatAudioSettings?
    
    public var broadcasting: StreamChatBroadcastSettings?
    
    public var screensharing: StreamChatScreensharingSettings?
    
    public var transcription: StreamChatTranscriptionSettings?
    
    public var backstage: StreamChatBackstageSettings?
    
    public init(geofencing: StreamChatGeofenceSettings?, recording: StreamChatRecordSettings?, ring: StreamChatRingSettings?, thumbnails: StreamChatThumbnailsSettings?, video: StreamChatVideoSettings?, audio: StreamChatAudioSettings?, broadcasting: StreamChatBroadcastSettings?, screensharing: StreamChatScreensharingSettings?, transcription: StreamChatTranscriptionSettings?, backstage: StreamChatBackstageSettings?) {
        self.geofencing = geofencing
        
        self.recording = recording
        
        self.ring = ring
        
        self.thumbnails = thumbnails
        
        self.video = video
        
        self.audio = audio
        
        self.broadcasting = broadcasting
        
        self.screensharing = screensharing
        
        self.transcription = transcription
        
        self.backstage = backstage
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case geofencing
        
        case recording
        
        case ring
        
        case thumbnails
        
        case video
        
        case audio
        
        case broadcasting
        
        case screensharing
        
        case transcription
        
        case backstage
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(geofencing, forKey: .geofencing)
        
        try container.encode(recording, forKey: .recording)
        
        try container.encode(ring, forKey: .ring)
        
        try container.encode(thumbnails, forKey: .thumbnails)
        
        try container.encode(video, forKey: .video)
        
        try container.encode(audio, forKey: .audio)
        
        try container.encode(broadcasting, forKey: .broadcasting)
        
        try container.encode(screensharing, forKey: .screensharing)
        
        try container.encode(transcription, forKey: .transcription)
        
        try container.encode(backstage, forKey: .backstage)
    }
}
