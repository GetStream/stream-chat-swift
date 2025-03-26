//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import UIKit

@MainActor public func Animate(
    duration: TimeInterval = 0.25,
    delay: TimeInterval = 0,
    _ actions: @escaping () -> Void,
    completion: ((Bool) -> Void)? = nil
) {
    Animate(
        duration: duration,
        delay: delay,
        isAnimated: true,
        actions,
        completion: completion
    )
}

@MainActor func Animate(
    duration: TimeInterval = 0.25,
    delay: TimeInterval = 0,
    isAnimated: Bool = true,
    _ actions: @escaping () -> Void,
    completion: ((Bool) -> Void)? = nil
) {
    guard isAnimated, !UIAccessibility.isReduceMotionEnabled else {
        actions()
        completion?(true)
        return
    }

    UIView.animate(
        withDuration: duration,
        delay: delay,
        usingSpringWithDamping: 0.8,
        initialSpringVelocity: 4,
        options: .curveEaseInOut,
        animations: actions,
        completion: completion
    )
}
