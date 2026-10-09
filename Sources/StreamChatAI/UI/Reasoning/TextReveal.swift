//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Reveals new text a little at a time, so thoughts that arrive in bursts read as a steady
/// stream. Text that does not carry on from what is shown replaces it at once.
@MainActor
final class TextReveal: ObservableObject {
    @Published private(set) var shown = ""
    private var target = ""
    private var pending: [Character] = []
    private var timer: Timer?

    func update(_ text: String, animated: Bool) {
        guard animated, text.utf8.count > target.utf8.count, text.utf8.starts(with: target.utf8) else {
            if text != shown || !pending.isEmpty { show(text) }
            return
        }
        pending.append(contentsOf: String(decoding: text.utf8.dropFirst(target.utf8.count), as: UTF8.self))
        target = text
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] timer in
            guard let self else { return timer.invalidate() }
            MainActor.assumeIsolated {
                self.tick()
            }
        }
    }

    /// Shows a fifth of the backlog at a time: new thoughts arrive about that often.
    func tick() {
        guard !pending.isEmpty else {
            timer?.invalidate()
            timer = nil
            return
        }
        let count = max(1, pending.count / 6)
        shown.append(contentsOf: pending.prefix(count))
        pending.removeFirst(count)
    }

    private func show(_ text: String) {
        timer?.invalidate()
        timer = nil
        pending = []
        target = text
        shown = text
    }
}
