//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat

// Caps the decoded bytes that all fully cached GIFs hold together. A GIF that does not fit
// falls back to a window of upcoming frames.
final class GIFMemoryBudget: Sendable {
    static let shared = GIFMemoryBudget(limit: 50 * 1024 * 1024)

    private let limit: Int
    private let reservedBytes = AllocatedUnfairLock(0)

    init(limit: Int) {
        self.limit = limit
    }

    func reserve(_ bytes: Int) -> Bool {
        reservedBytes.withLock { reservedBytes in
            guard reservedBytes + bytes <= limit else { return false }
            reservedBytes += bytes
            return true
        }
    }

    func release(_ bytes: Int) {
        reservedBytes.withLock { $0 -= bytes }
    }
}
