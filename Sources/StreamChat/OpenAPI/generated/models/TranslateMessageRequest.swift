//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct TranslateMessageRequest: Codable, Hashable {
    public var language: String

    public init(language: String) {
        self.language = language
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case language
    }
}
