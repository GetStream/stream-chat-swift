//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct MessageModerationDetailsPayload: Decodable {
    let originalText: String
    let action: String

    enum CodingKeys: String, CodingKey, CaseIterable {
        case originalText = "original_text"
        case action
    }
}
