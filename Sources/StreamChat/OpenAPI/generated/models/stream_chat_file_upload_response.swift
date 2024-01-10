//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFileUploadResponse: Codable, Hashable {
    public var thumbUrl: String?
    
    public var duration: String
    
    public var file: String?
    
    public init(thumbUrl: String?, duration: String, file: String?) {
        self.thumbUrl = thumbUrl
        
        self.duration = duration
        
        self.file = file
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case thumbUrl = "thumb_url"
        
        case duration
        
        case file
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(file, forKey: .file)
    }
}
