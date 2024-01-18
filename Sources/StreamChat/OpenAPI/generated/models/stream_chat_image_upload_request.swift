//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatImageUploadRequest: Codable, Hashable {
    public var user: StreamChatOnlyUserIDRequest?
    
    public var file: String?
    
    public var uploadSizes: [StreamChatImageSizeRequest]?
    
    public init(user: StreamChatOnlyUserIDRequest?, file: String?, uploadSizes: [StreamChatImageSizeRequest]?) {
        self.user = user
        
        self.file = file
        
        self.uploadSizes = uploadSizes
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
        
        case file
        
        case uploadSizes = "upload_sizes"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(file, forKey: .file)
        
        try container.encode(uploadSizes, forKey: .uploadSizes)
    }
}
