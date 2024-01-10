//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatImageUploadResponse: Codable, Hashable {
    public var duration: String
    
    public var file: String?
    
    public var thumbUrl: String?
    
    public var uploadSizes: [StreamChatImageSize]?
    
    public init(duration: String, file: String?, thumbUrl: String?, uploadSizes: [StreamChatImageSize]?) {
        self.duration = duration
        
        self.file = file
        
        self.thumbUrl = thumbUrl
        
        self.uploadSizes = uploadSizes
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case file
        
        case thumbUrl = "thumb_url"
        
        case uploadSizes = "upload_sizes"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(file, forKey: .file)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(uploadSizes, forKey: .uploadSizes)
    }
}
