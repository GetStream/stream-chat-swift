//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct SearchResult: Codable, Hashable {
    public var message: SearchResultMessage? = nil

    public init(message: SearchResultMessage? = nil) {
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case message
    }
}
