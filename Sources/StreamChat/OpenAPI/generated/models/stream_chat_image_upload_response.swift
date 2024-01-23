//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatImageUploadResponse: Codable, Hashable {
    public var duration: String
    
    public var file: String? = nil
    
    public var thumbUrl: String? = nil
    
    public var uploadSizes: [StreamChatImageSize]? = nil
    
    public init(duration: String, file: String? = nil, thumbUrl: String? = nil, uploadSizes: [StreamChatImageSize]? = nil) {
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
