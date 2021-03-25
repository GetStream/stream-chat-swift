//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

func Animate(delay: TimeInterval = 0, _ actions: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
    guard !UIAccessibility.isReduceMotionEnabled else {
        actions()
        completion?(true)
        return
    }
    
    UIView.animate(
        withDuration: 0.25,
        delay: delay,
        usingSpringWithDamping: 0.8,
        initialSpringVelocity: 4,
        options: .curveEaseInOut,
        animations: actions,
        completion: completion
    )
}
