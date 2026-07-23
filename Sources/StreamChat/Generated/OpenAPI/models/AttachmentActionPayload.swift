//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class AttachmentActionPayload: Sendable, Codable, JSONEncodable {
    let name: String
    let style: String?
    let text: String
    let type: String
    let value: String?

    init(
        name: String,
        style: String? = nil,
        text: String,
        type: String,
        value: String? = nil
    ) {
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
