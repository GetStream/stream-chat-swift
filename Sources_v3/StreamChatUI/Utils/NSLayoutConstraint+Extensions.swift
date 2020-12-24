//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

extension UILayoutPriority {
    /// The `UILayoutPriority` that is less than required by 1.
    ///
    /// Such helper is especially handy when working with `UIStackView`:
    /// when the arranged subview is hidden, the constraint for `height == 0`
    /// with `.required` priority is activated.
    ///
    /// Having all height constraints inside the `UIStackView` with `almostRequired`
    /// priority eliminates breaking constraints warnings in console.
    static let almostRequired: Self = .required - 1
}

extension NSLayoutConstraint {
    /// Changes the priority of `self` to the provided one.
    /// - Parameter priority: The priority to be applied.
    /// - Returns: `self` with updated `priority`.
    func with(priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }

    /// Returns updated `self` with `priority == .almostRequired`
    var almostRequired: NSLayoutConstraint {
        with(priority: .almostRequired)
    }
}
