//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension SyncResponse: Decodable {
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            events: container.decodeArrayIgnoringFailures([WSEvent].self, forKey: .events),
            inaccessibleCids: container.decodeIfPresent([String].self, forKey: .inaccessibleCids)
        )
    }
}
