//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFileUploadConfig: Codable, Hashable {
    public var blockedFileExtensions: [String]
    
    public var blockedMimeTypes: [String]
    
    public var allowedFileExtensions: [String]
    
    public var allowedMimeTypes: [String]
    
    public init(blockedFileExtensions: [String], blockedMimeTypes: [String], allowedFileExtensions: [String], allowedMimeTypes: [String]) {
        self.blockedFileExtensions = blockedFileExtensions
        
        self.blockedMimeTypes = blockedMimeTypes
        
        self.allowedFileExtensions = allowedFileExtensions
        
        self.allowedMimeTypes = allowedMimeTypes
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case blockedFileExtensions = "blocked_file_extensions"
        
        case blockedMimeTypes = "blocked_mime_types"
        
        case allowedFileExtensions = "allowed_file_extensions"
        
        case allowedMimeTypes = "allowed_mime_types"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(blockedFileExtensions, forKey: .blockedFileExtensions)
        
        try container.encode(blockedMimeTypes, forKey: .blockedMimeTypes)
        
        try container.encode(allowedFileExtensions, forKey: .allowedFileExtensions)
        
        try container.encode(allowedMimeTypes, forKey: .allowedMimeTypes)
    }
}
