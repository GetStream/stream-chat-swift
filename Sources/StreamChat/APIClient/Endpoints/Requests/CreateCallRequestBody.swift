//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct CallRequestBody: Encodable {
    private enum CodingKeys: String, CodingKey {
        case id
        case type
    }

    let id: String
    let type: String
}
