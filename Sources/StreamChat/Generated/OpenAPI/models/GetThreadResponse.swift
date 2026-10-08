//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetThreadResponse: Sendable, Decodable {
    let thread: ThreadStateResponse

    init(thread: ThreadStateResponse) {
        self.thread = thread
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.thread = try container.decode(ThreadStateResponse.self, forKey: .thread)
    }
}
