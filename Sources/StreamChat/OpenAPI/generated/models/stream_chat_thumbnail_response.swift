//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatThumbnailResponse: Codable, Hashable {
    public var imageUrl: String
    
    public init(imageUrl: String) {
        self.imageUrl = imageUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case imageUrl = "image_url"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(imageUrl, forKey: .imageUrl)
    }
}
