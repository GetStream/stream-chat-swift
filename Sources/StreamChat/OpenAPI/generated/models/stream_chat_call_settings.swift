//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallSettings: Codable, Hashable {
    public var thumbnails: StreamChatThumbnailsSettings?
    
    public var audio: StreamChatAudioSettings?
    
    public var backstage: StreamChatBackstageSettings?
    
    public var recording: StreamChatRecordSettings?
    
    public var ring: StreamChatRingSettings?
    
    public var screensharing: StreamChatScreensharingSettings?
    
    public var transcription: StreamChatTranscriptionSettings?
    
    public var video: StreamChatVideoSettings?
    
    public var broadcasting: StreamChatBroadcastSettings?
    
    public var geofencing: StreamChatGeofenceSettings?
    
    public init(thumbnails: StreamChatThumbnailsSettings?, audio: StreamChatAudioSettings?, backstage: StreamChatBackstageSettings?, recording: StreamChatRecordSettings?, ring: StreamChatRingSettings?, screensharing: StreamChatScreensharingSettings?, transcription: StreamChatTranscriptionSettings?, video: StreamChatVideoSettings?, broadcasting: StreamChatBroadcastSettings?, geofencing: StreamChatGeofenceSettings?) {
        self.thumbnails = thumbnails
        
        self.audio = audio
        
        self.backstage = backstage
        
        self.recording = recording
        
        self.ring = ring
        
        self.screensharing = screensharing
        
        self.transcription = transcription
        
        self.video = video
        
        self.broadcasting = broadcasting
        
        self.geofencing = geofencing
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case thumbnails
        
        case audio
        
        case backstage
        
        case recording
        
        case ring
        
        case screensharing
        
        case transcription
        
        case video
        
        case broadcasting
        
        case geofencing
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(thumbnails, forKey: .thumbnails)
        
        try container.encode(audio, forKey: .audio)
        
        try container.encode(backstage, forKey: .backstage)
        
        try container.encode(recording, forKey: .recording)
        
        try container.encode(ring, forKey: .ring)
        
        try container.encode(screensharing, forKey: .screensharing)
        
        try container.encode(transcription, forKey: .transcription)
        
        try container.encode(video, forKey: .video)
        
        try container.encode(broadcasting, forKey: .broadcasting)
        
        try container.encode(geofencing, forKey: .geofencing)
    }
}
