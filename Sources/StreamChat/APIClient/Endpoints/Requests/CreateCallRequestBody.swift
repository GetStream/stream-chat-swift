//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

struct CreateCallRequestBody: Encodable {
    private enum CodingKeys: String, CodingKey {
        case id
        case type
    }
    
    let id: String
    let type: String
}
