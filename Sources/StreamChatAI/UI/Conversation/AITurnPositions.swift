//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

// Where the turn at the top of what is visible is, for keeping it in place when something
// arrives above it. It is read only then, so scrolling does not lay the list out again.
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

    private var held: Held?
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

    func update(_ frames: [AnyHashable: CGRect]) {
        guard !isHolding else { return }
        var top: Held?
        for (id, frame) in frames where frame.maxY > 0 && frame.minY < (top?.frame.minY ?? .infinity) {
            top = Held(id: id, frame: frame)
        }
        held = top
    }

    // The turn that was at the top before what is above the turns changed, if it is still in
    // the list.
    func heldTurn(among ids: Set<AnyHashable>) -> Held? {
        held.flatMap { ids.contains($0.id) ? $0 : nil }
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
