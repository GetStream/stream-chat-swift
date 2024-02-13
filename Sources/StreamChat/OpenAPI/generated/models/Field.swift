//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Field: Codable, Hashable {
    public var short: Bool
    public var title: String
    public var value: String

    public init(short: Bool, title: String, value: String) {
        self.short = short
        self.title = title
        self.value = value
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case short
        case title
        case value
    }
}
