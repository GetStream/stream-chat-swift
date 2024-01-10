//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallSettings: Codable, Hashable {
    public var backstage: StreamChatBackstageSettings?
    
    public var screensharing: StreamChatScreensharingSettings?
    
    public var thumbnails: StreamChatThumbnailsSettings?
    
    public var video: StreamChatVideoSettings?
    
    public var audio: StreamChatAudioSettings?
    
    public var broadcasting: StreamChatBroadcastSettings?
    
    public var geofencing: StreamChatGeofenceSettings?
    
    public var recording: StreamChatRecordSettings?
    
    public var ring: StreamChatRingSettings?
    
    public var transcription: StreamChatTranscriptionSettings?
    
    public init(backstage: StreamChatBackstageSettings?, screensharing: StreamChatScreensharingSettings?, thumbnails: StreamChatThumbnailsSettings?, video: StreamChatVideoSettings?, audio: StreamChatAudioSettings?, broadcasting: StreamChatBroadcastSettings?, geofencing: StreamChatGeofenceSettings?, recording: StreamChatRecordSettings?, ring: StreamChatRingSettings?, transcription: StreamChatTranscriptionSettings?) {
        self.backstage = backstage
        
        self.screensharing = screensharing
        
        self.thumbnails = thumbnails
        
        self.video = video
        
        self.audio = audio
        
        self.broadcasting = broadcasting
        
        self.geofencing = geofencing
        
        self.recording = recording
        
        self.ring = ring
        
        self.transcription = transcription
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case backstage
        
        case screensharing
        
        case thumbnails
        
        case video
        
        case audio
        
        case broadcasting
        
        case geofencing
        
        case recording
        
        case ring
        
        case transcription
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(backstage, forKey: .backstage)
        
        try container.encode(screensharing, forKey: .screensharing)
        
        try container.encode(thumbnails, forKey: .thumbnails)
        
        try container.encode(video, forKey: .video)
        
        try container.encode(audio, forKey: .audio)
        
        try container.encode(broadcasting, forKey: .broadcasting)
        
        try container.encode(geofencing, forKey: .geofencing)
        
        try container.encode(recording, forKey: .recording)
        
        try container.encode(ring, forKey: .ring)
        
        try container.encode(transcription, forKey: .transcription)
    }
}
