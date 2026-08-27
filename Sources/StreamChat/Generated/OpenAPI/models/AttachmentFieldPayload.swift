//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

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
