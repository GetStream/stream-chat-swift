//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A cost-bounded, in-memory LRU cache for decoded images.
///
/// Thread-safe via a single ``AllocatedUnfairLock``. Eviction is least-recently-used:
/// a lookup refreshes an entry's recency and inserting past the cost limit removes the
/// oldest entries first.
final class ImageMemoryCache: @unchecked Sendable {
    private struct Entry {
        let image: DownloadedImage
        let cost: Int
        var lastUsedAt: UInt64
    }

    private struct State {
        var entries: [String: Entry] = [:]
        var totalCost: Int = 0
        var clock: UInt64 = 0
    }

    /// The maximum total size, in bytes, of the decoded images kept in memory.
    let maxSizeInBytes: Int

    private var entrySizeLimit: Int {
        Int(Double(maxSizeInBytes) * 0.5)
    }

    private let state = AllocatedUnfairLock(State())

    init(maxSizeInBytes: Int) {
        self.maxSizeInBytes = maxSizeInBytes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func image(forKey key: String) -> DownloadedImage? {
        state.withLock { state in
            guard var entry = state.entries[key] else { return nil }
            state.clock &+= 1
            entry.lastUsedAt = state.clock
            state.entries[key] = entry
            return entry.image
        }
    }

    func store(_ image: DownloadedImage, forKey key: String) {
        let cost = Self.cost(of: image)
        guard cost <= entrySizeLimit else { return }
        state.withLock { state in
            if let existing = state.entries[key] {
                state.totalCost -= existing.cost
            }
            state.clock &+= 1
            state.entries[key] = Entry(image: image, cost: cost, lastUsedAt: state.clock)
            state.totalCost += cost
            Self.evict(&state, toCost: maxSizeInBytes)
        }
    }

    func removeAll() {
        state.withLock { state in
            state.entries.removeAll()
            state.totalCost = 0
        }
    }

    func trim(toCost limit: Int) {
        state.withLock { state in
            Self.evict(&state, toCost: limit)
        }
    }

    var totalCost: Int {
        state.withLock { $0.totalCost }
    }

    // MARK: - Private

    private static func evict(_ state: inout State, toCost limit: Int) {
        guard state.totalCost > limit else { return }
        let sortedByRecency = state.entries.sorted { $0.value.lastUsedAt < $1.value.lastUsedAt }
        for (key, entry) in sortedByRecency {
            guard state.totalCost > limit else { break }
            state.entries.removeValue(forKey: key)
            state.totalCost -= entry.cost
        }
    }

    private static func cost(of image: DownloadedImage) -> Int {
        let dataCost = image.animatedImageData?.count ?? 0
        guard let cgImage = image.image.cgImage else {
            return max(1, dataCost)
        }
        return cgImage.bytesPerRow * cgImage.height + dataCost
    }

    @objc private func handleMemoryWarning() {
        removeAll()
    }

    @objc private func handleDidEnterBackground() {
        trim(toCost: Int(Double(maxSizeInBytes) * 0.1))
    }
}
