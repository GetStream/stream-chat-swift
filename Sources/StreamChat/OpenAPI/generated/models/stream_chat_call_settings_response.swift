//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallSettingsResponse: Codable, Hashable {
    public var audio: StreamChatAudioSettings
    
    public var broadcasting: StreamChatBroadcastSettingsResponse
    
    public var recording: StreamChatRecordSettingsResponse
    
    public var ring: StreamChatRingSettings
    
    public var thumbnails: StreamChatThumbnailsSettings
    
    public var video: StreamChatVideoSettings
    
    public var backstage: StreamChatBackstageSettings
    
    public var geofencing: StreamChatGeofenceSettings
    
    public var screensharing: StreamChatScreensharingSettings
    
    public var transcription: StreamChatTranscriptionSettings
    
    public init(audio: StreamChatAudioSettings, broadcasting: StreamChatBroadcastSettingsResponse, recording: StreamChatRecordSettingsResponse, ring: StreamChatRingSettings, thumbnails: StreamChatThumbnailsSettings, video: StreamChatVideoSettings, backstage: StreamChatBackstageSettings, geofencing: StreamChatGeofenceSettings, screensharing: StreamChatScreensharingSettings, transcription: StreamChatTranscriptionSettings) {
        self.audio = audio
        
        self.broadcasting = broadcasting
        
        self.recording = recording
        
        self.ring = ring
        
        self.thumbnails = thumbnails
        
        self.video = video
        
        self.backstage = backstage
        
        self.geofencing = geofencing
        
        self.screensharing = screensharing
        
        self.transcription = transcription
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case audio
        
        case broadcasting
        
        case recording
        
        case ring
        
        case thumbnails
        
        case video
        
        case backstage
        
        case geofencing
        
        case screensharing
        
        case transcription
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(audio, forKey: .audio)
        
        try container.encode(broadcasting, forKey: .broadcasting)
        
        try container.encode(recording, forKey: .recording)
        
        try container.encode(ring, forKey: .ring)
        
        try container.encode(thumbnails, forKey: .thumbnails)
        
        try container.encode(video, forKey: .video)
        
        try container.encode(backstage, forKey: .backstage)
        
        try container.encode(geofencing, forKey: .geofencing)
        
        try container.encode(screensharing, forKey: .screensharing)
        
        try container.encode(transcription, forKey: .transcription)
    }
}
