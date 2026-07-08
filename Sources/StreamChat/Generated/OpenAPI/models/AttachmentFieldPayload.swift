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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case short
        case title
        case value
    }
}

extension AttachmentFieldPayload: Hashable {
    static func == (lhs: AttachmentFieldPayload, rhs: AttachmentFieldPayload) -> Bool {
        lhs.short == rhs.short &&
            lhs.title == rhs.title &&
            lhs.value == rhs.value
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(short)
        hasher.combine(title)
        hasher.combine(value)
    }
}
