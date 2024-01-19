//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallSettingsResponse: Codable, Hashable {
    public var ring: StreamChatRingSettings
    
    public var thumbnails: StreamChatThumbnailsSettings
    
    public var video: StreamChatVideoSettings
    
    public var audio: StreamChatAudioSettings
    
    public var backstage: StreamChatBackstageSettings
    
    public var broadcasting: StreamChatBroadcastSettingsResponse
    
    public var geofencing: StreamChatGeofenceSettings
    
    public var recording: StreamChatRecordSettingsResponse
    
    public var screensharing: StreamChatScreensharingSettings
    
    public var transcription: StreamChatTranscriptionSettings
    
    public init(ring: StreamChatRingSettings, thumbnails: StreamChatThumbnailsSettings, video: StreamChatVideoSettings, audio: StreamChatAudioSettings, backstage: StreamChatBackstageSettings, broadcasting: StreamChatBroadcastSettingsResponse, geofencing: StreamChatGeofenceSettings, recording: StreamChatRecordSettingsResponse, screensharing: StreamChatScreensharingSettings, transcription: StreamChatTranscriptionSettings) {
        self.ring = ring
        
        self.thumbnails = thumbnails
        
        self.video = video
        
        self.audio = audio
        
        self.backstage = backstage
        
        self.broadcasting = broadcasting
        
        self.geofencing = geofencing
        
        self.recording = recording
        
        self.screensharing = screensharing
        
        self.transcription = transcription
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case ring
        
        case thumbnails
        
        case video
        
        case audio
        
        case backstage
        
        case broadcasting
        
        case geofencing
        
        case recording
        
        case screensharing
        
        case transcription
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(ring, forKey: .ring)
        
        try container.encode(thumbnails, forKey: .thumbnails)
        
        try container.encode(video, forKey: .video)
        
        try container.encode(audio, forKey: .audio)
        
        try container.encode(backstage, forKey: .backstage)
        
        try container.encode(broadcasting, forKey: .broadcasting)
        
        try container.encode(geofencing, forKey: .geofencing)
        
        try container.encode(recording, forKey: .recording)
        
        try container.encode(screensharing, forKey: .screensharing)
        
        try container.encode(transcription, forKey: .transcription)
    }
}
