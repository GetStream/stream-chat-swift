//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct CallSettings: Codable, Hashable {
    public var audio: AudioSettings? = nil
    
    public var backstage: BackstageSettings? = nil
    
    public var broadcasting: BroadcastSettings? = nil
    
    public var geofencing: GeofenceSettings? = nil
    
    public var recording: RecordSettings? = nil
    
    public var ring: RingSettings? = nil
    
    public var screensharing: ScreensharingSettings? = nil
    
    public var thumbnails: ThumbnailsSettings? = nil
    
    public var transcription: TranscriptionSettings? = nil
    
    public var video: VideoSettings? = nil
    
    public init(audio: AudioSettings? = nil, backstage: BackstageSettings? = nil, broadcasting: BroadcastSettings? = nil, geofencing: GeofenceSettings? = nil, recording: RecordSettings? = nil, ring: RingSettings? = nil, screensharing: ScreensharingSettings? = nil, thumbnails: ThumbnailsSettings? = nil, transcription: TranscriptionSettings? = nil, video: VideoSettings? = nil) {
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
