//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFileUploadResponse: Codable, Hashable {
    public var file: String?
    
    public var thumbUrl: String?
    
    public var duration: String
    
    public init(file: String?, thumbUrl: String?, duration: String) {
        self.file = file
        
        self.thumbUrl = thumbUrl
        
        self.duration = duration
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case file
        
        case thumbUrl = "thumb_url"
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(file, forKey: .file)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(duration, forKey: .duration)
    }
}
