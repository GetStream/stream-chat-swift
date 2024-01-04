//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatTranslateMessageRequest: Codable, Hashable {
    public var language: String
    
    public init(language: String) {
        self.language = language
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case language
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(language, forKey: .language)
    }
}
