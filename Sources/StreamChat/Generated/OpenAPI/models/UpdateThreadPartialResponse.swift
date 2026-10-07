//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateThreadPartialResponse: Sendable, Decodable {
    let thread: ThreadResponse

    init(thread: ThreadResponse) {
        self.thread = thread
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.thread = try container.decode(ThreadResponse.self, forKey: .thread)
    }
}
