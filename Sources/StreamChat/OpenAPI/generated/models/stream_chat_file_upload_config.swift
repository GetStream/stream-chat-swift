//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFileUploadConfig: Codable, Hashable {
    public var blockedMimeTypes: [String]
    
    public var allowedFileExtensions: [String]
    
    public var allowedMimeTypes: [String]
    
    public var blockedFileExtensions: [String]
    
    public init(blockedMimeTypes: [String], allowedFileExtensions: [String], allowedMimeTypes: [String], blockedFileExtensions: [String]) {
        self.blockedMimeTypes = blockedMimeTypes
        
        self.allowedFileExtensions = allowedFileExtensions
        
        self.allowedMimeTypes = allowedMimeTypes
        
        self.blockedFileExtensions = blockedFileExtensions
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case blockedMimeTypes = "blocked_mime_types"
        
        case allowedFileExtensions = "allowed_file_extensions"
        
        case allowedMimeTypes = "allowed_mime_types"
        
        case blockedFileExtensions = "blocked_file_extensions"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(blockedMimeTypes, forKey: .blockedMimeTypes)
        
        try container.encode(allowedFileExtensions, forKey: .allowedFileExtensions)
        
        try container.encode(allowedMimeTypes, forKey: .allowedMimeTypes)
        
        try container.encode(blockedFileExtensions, forKey: .blockedFileExtensions)
    }
}
