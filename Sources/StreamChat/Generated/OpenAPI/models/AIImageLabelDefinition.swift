//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AIImageLabelDefinition: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var description: String
    var group: String
    var key: String
    var label: String

    init(description: String, group: String, key: String, label: String) {
        self.description = description
        self.group = group
        self.key = key
        self.label = label
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case description
        case group
        case key
        case label
    }

    static func == (lhs: AIImageLabelDefinition, rhs: AIImageLabelDefinition) -> Bool {
        lhs.description == rhs.description &&
            lhs.group == rhs.group &&
            lhs.key == rhs.key &&
            lhs.label == rhs.label
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(description)
        hasher.combine(group)
        hasher.combine(key)
        hasher.combine(label)
    }
}
