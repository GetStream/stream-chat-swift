//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallSettingsRequest: Codable, Hashable {
    public var broadcasting: StreamChatBroadcastSettingsRequest?
    
    public var recording: StreamChatRecordSettingsRequest?
    
    public var thumbnails: StreamChatThumbnailsSettingsRequest?
    
    public var video: StreamChatVideoSettingsRequest?
    
    public var audio: StreamChatAudioSettingsRequest?
    
    public var backstage: StreamChatBackstageSettingsRequest?
    
    public var geofencing: StreamChatGeofenceSettingsRequest?
    
    public var ring: StreamChatRingSettingsRequest?
    
    public var screensharing: StreamChatScreensharingSettingsRequest?
    
    public var transcription: StreamChatTranscriptionSettingsRequest?
    
    public init(broadcasting: StreamChatBroadcastSettingsRequest?, recording: StreamChatRecordSettingsRequest?, thumbnails: StreamChatThumbnailsSettingsRequest?, video: StreamChatVideoSettingsRequest?, audio: StreamChatAudioSettingsRequest?, backstage: StreamChatBackstageSettingsRequest?, geofencing: StreamChatGeofenceSettingsRequest?, ring: StreamChatRingSettingsRequest?, screensharing: StreamChatScreensharingSettingsRequest?, transcription: StreamChatTranscriptionSettingsRequest?) {
        self.broadcasting = broadcasting
        
        self.recording = recording
        
        self.thumbnails = thumbnails
        
        self.video = video
        
        self.audio = audio
        
        self.backstage = backstage
        
        self.geofencing = geofencing
        
        self.ring = ring
        
        self.screensharing = screensharing
        
        self.transcription = transcription
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case broadcasting
        
        case recording
        
        case thumbnails
        
        case video
        
        case audio
        
        case backstage
        
        case geofencing
        
        case ring
        
        case screensharing
        
        case transcription
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(broadcasting, forKey: .broadcasting)
        
        try container.encode(recording, forKey: .recording)
        
        try container.encode(thumbnails, forKey: .thumbnails)
        
        try container.encode(video, forKey: .video)
        
        try container.encode(audio, forKey: .audio)
        
        try container.encode(backstage, forKey: .backstage)
        
        try container.encode(geofencing, forKey: .geofencing)
        
        try container.encode(ring, forKey: .ring)
        
        try container.encode(screensharing, forKey: .screensharing)
        
        try container.encode(transcription, forKey: .transcription)
    }
}
