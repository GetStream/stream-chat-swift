//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class Action: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var name: String
    var style: String?
    var text: String
    var type: String
    var value: String?

    init(name: String, style: String? = nil, text: String, type: String, value: String? = nil) {
        self.name = name
        self.style = style
        self.text = text
        self.type = type
        self.value = value
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        case style
        case text
        case type
        case value
    }

    static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.name == rhs.name &&
            lhs.style == rhs.style &&
            lhs.text == rhs.text &&
            lhs.type == rhs.type &&
            lhs.value == rhs.value
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(style)
        hasher.combine(text)
        hasher.combine(type)
        hasher.combine(value)
    }
}
