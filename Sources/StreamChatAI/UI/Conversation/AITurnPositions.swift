//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

// Where the turns in view are, for keeping the top one in place when something arrives above
// it. They are read only then, so scrolling does not lay the list out again.
@MainActor
final class AITurnPositions {
    struct Held {
        let id: AnyHashable
        // Where the turn was, with 0 at the top of what is visible.
        let frame: CGRect

        // The point of the turn that, aligned with the same point of a list `height` tall, puts
        // its top back where it was.
        func anchor(in height: CGFloat) -> UnitPoint {
            let room = height - frame.height
            guard abs(room) >= 1 else { return .top }
            return UnitPoint(x: 0.5, y: frame.minY / room)
        }
    }

    // The turns in view, the one at the top of what is visible first.
    private var held: [Held] = []
    private var above: AnyHashable?
    // Whether what is above the turns changed and the turn at the top is not back yet. The
    // frames of the layout that follows the change would hold the turn that arrived instead.
    private var isHolding = false

    nonisolated init() { /* Nothing to set up. */ }

    // Notes what is above the turns, on every update and before its layout.
    func expect(above: AnyHashable) {
        guard above != self.above else { return }
        if self.above != nil {
            isHolding = true
        }
        self.above = above
    }

    // Notes the turns in a list `height` tall, apart from those out of view, which the list may
    // still have laid out.
    func update(_ frames: [AnyHashable: CGRect], height: CGFloat) {
        guard !isHolding else { return }
        held = frames
            .compactMap { $0.value.maxY > 0 && $0.value.minY < height ? Held(id: $0.key, frame: $0.value) : nil }
            .sorted { $0.frame.minY < $1.frame.minY }
    }

    // The turn nearest the top of what was visible before what is above the turns changed that
    // is still in the list. The top one can be gone: a turn that starts with a reply joins the
    // turn of its question when older messages bring it.
    func heldTurn(among ids: Set<AnyHashable>) -> Held? {
        held.first { ids.contains($0.id) }
    }

    // The turn at the top is back where it was, or cannot be.
    func release() {
        isHolding = false
    }
}

// The frames of the turns in view, with 0 at the top of what is visible.
struct AITurnFrames: PreferenceKey {
    static var defaultValue: [AnyHashable: CGRect] { [:] }

    static func reduce(value: inout [AnyHashable: CGRect], nextValue: () -> [AnyHashable: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}
