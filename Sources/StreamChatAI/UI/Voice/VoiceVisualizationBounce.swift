//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// The bounce of a tap: a dip to 93% and an overshoot to 103% before settling, over 340 ms.
//
// These are authored keyframes rather than a spring. Like the web reference's animation, the
// ease-out curve times the whole run and the keyframes are linear between their stops.
struct VoiceVisualizationBounce {
    static let duration: Float = 0.34

    private static let keyframes: [(offset: Float, scale: Float)] = [
        (0, 1),
        (0.3, 0.93),
        (0.62, 1.03),
        (1, 1)
    ]

    private var age: Float = .infinity

    mutating func start() {
        age = 0
    }

    mutating func advance(by seconds: Float) {
        age += seconds
    }

    var scale: Float {
        guard age < Self.duration else { return 1 }
        return Self.scale(at: Self.easeOut(max(age, 0) / Self.duration))
    }

    static func scale(at progress: Float) -> Float {
        for (start, end) in zip(keyframes, keyframes.dropFirst()) where progress <= end.offset {
            let fraction = (progress - start.offset) / (end.offset - start.offset)
            return start.scale + (end.scale - start.scale) * fraction
        }
        return 1
    }

    // CSS `ease-out`, `cubic-bezier(0, 0, 0.58, 1)`.
    static func easeOut(_ x: Float) -> Float {
        let (x1, y1, x2, y2): (Float, Float, Float, Float) = (0, 0, 0.58, 1)
        let cx = 3 * x1
        let bx = 3 * (x2 - x1) - cx
        let ax = 1 - cx - bx
        let cy = 3 * y1
        let by = 3 * (y2 - y1) - cy
        let ay = 1 - cy - by
        func sampleX(_ t: Float) -> Float { ((ax * t + bx) * t + cx) * t }
        func sampleY(_ t: Float) -> Float { ((ay * t + by) * t + cy) * t }

        var low: Float = 0
        var high: Float = 1
        for _ in 0..<24 {
            let middle = (low + high) / 2
            if sampleX(middle) < x {
                low = middle
            } else {
                high = middle
            }
        }
        return sampleY((low + high) / 2)
    }
}
