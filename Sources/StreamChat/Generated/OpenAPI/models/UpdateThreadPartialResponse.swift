//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateThreadPartialResponse: Sendable, Decodable {
    let thread: ThreadResponse

    init(thread: ThreadResponse) {
        self.thread = thread
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case thread
    }
}
