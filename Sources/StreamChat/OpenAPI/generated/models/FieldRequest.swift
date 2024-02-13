//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct FieldRequest: Codable, Hashable {
    public var short: Bool? = nil
    public var title: String? = nil
    public var value: String? = nil

    public init(short: Bool? = nil, title: String? = nil, value: String? = nil) {
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
