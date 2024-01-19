//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallSettingsRequest: Codable, Hashable {
    public var broadcasting: StreamChatBroadcastSettingsRequest?
    
    public var transcription: StreamChatTranscriptionSettingsRequest?
    
    public var video: StreamChatVideoSettingsRequest?
    
    public var ring: StreamChatRingSettingsRequest?
    
    public var screensharing: StreamChatScreensharingSettingsRequest?
    
    public var thumbnails: StreamChatThumbnailsSettingsRequest?
    
    public var audio: StreamChatAudioSettingsRequest?
    
    public var backstage: StreamChatBackstageSettingsRequest?
    
    public var geofencing: StreamChatGeofenceSettingsRequest?
    
    public var recording: StreamChatRecordSettingsRequest?
    
    public init(broadcasting: StreamChatBroadcastSettingsRequest?, transcription: StreamChatTranscriptionSettingsRequest?, video: StreamChatVideoSettingsRequest?, ring: StreamChatRingSettingsRequest?, screensharing: StreamChatScreensharingSettingsRequest?, thumbnails: StreamChatThumbnailsSettingsRequest?, audio: StreamChatAudioSettingsRequest?, backstage: StreamChatBackstageSettingsRequest?, geofencing: StreamChatGeofenceSettingsRequest?, recording: StreamChatRecordSettingsRequest?) {
        self.broadcasting = broadcasting
        
        self.transcription = transcription
        
        self.video = video
        
        self.ring = ring
        
        self.screensharing = screensharing
        
        self.thumbnails = thumbnails
        
        self.audio = audio
        
        self.backstage = backstage
        
        self.geofencing = geofencing
        
        self.recording = recording
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case broadcasting
        
        case transcription
        
        case video
        
        case ring
        
        case screensharing
        
        case thumbnails
        
        case audio
        
        case backstage
        
        case geofencing
        
        case recording
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(broadcasting, forKey: .broadcasting)
        
        try container.encode(transcription, forKey: .transcription)
        
        try container.encode(video, forKey: .video)
        
        try container.encode(ring, forKey: .ring)
        
        try container.encode(screensharing, forKey: .screensharing)
        
        try container.encode(thumbnails, forKey: .thumbnails)
        
        try container.encode(audio, forKey: .audio)
        
        try container.encode(backstage, forKey: .backstage)
        
        try container.encode(geofencing, forKey: .geofencing)
        
        try container.encode(recording, forKey: .recording)
    }
}
