//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AttachmentFieldPayload: Sendable, Codable, JSONEncodable {
    let short: Bool
    let title: String
    let value: String

    init(short: Bool, title: String, value: String) {
        self.short = short
        self.title = title
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.short = try container.decode(Bool.self, forKey: .short)
        self.title = try container.decode(String.self, forKey: .title)
        self.value = try container.decode(String.self, forKey: .value)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(short, forKey: .short)
        try container.encode(title, forKey: .title)
        try container.encode(value, forKey: .value)
    }
}
