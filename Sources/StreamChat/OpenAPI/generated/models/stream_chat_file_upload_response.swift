//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFileUploadResponse: Codable, Hashable {
    public var duration: String
    
    public var file: String?
    
    public var thumbUrl: String?
    
    public init(duration: String, file: String?, thumbUrl: String?) {
        self.duration = duration
        
        self.file = file
        
        self.thumbUrl = thumbUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case file
        
        case thumbUrl = "thumb_url"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(file, forKey: .file)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
    }
}
