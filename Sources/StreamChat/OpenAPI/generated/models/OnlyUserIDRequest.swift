//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct OnlyUserIDRequest: Codable, Hashable {
    public var id: String

    public init(id: String) {
        self.id = id
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
    }
}
