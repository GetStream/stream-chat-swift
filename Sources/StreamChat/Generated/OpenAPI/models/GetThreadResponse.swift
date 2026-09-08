//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetThreadResponse: Sendable, Decodable {
    let thread: ThreadStateResponse

    init(thread: ThreadStateResponse) {
        self.thread = thread
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case thread
    }
}
