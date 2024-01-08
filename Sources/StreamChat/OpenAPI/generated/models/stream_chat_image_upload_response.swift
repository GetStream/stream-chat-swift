//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatImageUploadResponse: Codable, Hashable {
    public var thumbUrl: String?
    
    public var uploadSizes: [StreamChatImageSize]?
    
    public var duration: String
    
    public var file: String?
    
    public init(thumbUrl: String?, uploadSizes: [StreamChatImageSize]?, duration: String, file: String?) {
        self.thumbUrl = thumbUrl
        
        self.uploadSizes = uploadSizes
        
        self.duration = duration
        
        self.file = file
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case thumbUrl = "thumb_url"
        
        case uploadSizes = "upload_sizes"
        
        case duration
        
        case file
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(uploadSizes, forKey: .uploadSizes)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(file, forKey: .file)
    }
}
