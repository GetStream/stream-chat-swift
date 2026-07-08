//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AttachmentActionPayload: Sendable, Codable, JSONEncodable {
    let name: String
    let style: String?
    let text: String
    let type: String
    let value: String?

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
}

extension AttachmentActionPayload: Hashable {
    static func == (lhs: AttachmentActionPayload, rhs: AttachmentActionPayload) -> Bool {
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
