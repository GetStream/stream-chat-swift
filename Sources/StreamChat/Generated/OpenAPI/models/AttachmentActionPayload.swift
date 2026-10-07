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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.style = try container.decodeIfPresent(String.self, forKey: .style)
        self.text = try container.decode(String.self, forKey: .text)
        self.type = try container.decode(String.self, forKey: .type)
        self.value = try container.decodeIfPresent(String.self, forKey: .value)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(style, forKey: .style)
        try container.encode(text, forKey: .text)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(value, forKey: .value)
    }
}
