//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFileUploadRequest: Codable, Hashable {
    public var file: String? = nil
    
    public var user: StreamChatOnlyUserIDRequest? = nil
    
    public init(file: String? = nil, user: StreamChatOnlyUserIDRequest? = nil) {
        self.file = file
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case file
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(file, forKey: .file)
        
        try container.encode(user, forKey: .user)
    }
}
