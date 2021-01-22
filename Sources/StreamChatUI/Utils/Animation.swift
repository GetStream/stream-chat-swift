//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

func Animate(_ actions: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
    guard !UIAccessibility.isReduceMotionEnabled else {
        actions()
        completion?(true)
        return
    }
    
    UIView.animate(
        withDuration: 0.25,
        delay: 0,
        usingSpringWithDamping: 0.8,
        initialSpringVelocity: 4,
        options: .curveEaseInOut,
        animations: actions,
        completion: completion
    )
}
