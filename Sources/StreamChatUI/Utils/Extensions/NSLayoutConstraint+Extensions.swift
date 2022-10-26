//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

extension UILayoutPriority {
    /// Having our default priority lower than `.required(1000)` allow user easily
    /// override any default constraints and customize layout
    static let streamRequire = UILayoutPriority(rawValue: 900)
    static let streamAlmostRequire: UILayoutPriority = .streamRequire - 1

    /// The default low priority used for the default layouts. It's higher than the system `defaultLow`.
    static let streamLow = UILayoutPriority.defaultLow + 10
}

extension NSLayoutConstraint {
    /// Changes the priority of `self` to the provided one.
    /// - Parameter priority: The priority to be applied.
    /// - Returns: `self` with updated `priority`.
    func with(priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }

    /// Returns updated `self` with `priority == .streamAlmostRequire`
    var almostRequired: NSLayoutConstraint {
        with(priority: .streamAlmostRequire)
    }
}

extension NSLayoutAnchor {
    // These methods return an inactive constraint of the form thisAnchor = otherAnchor.
    @objc func pin(equalTo anchor: NSLayoutAnchor<AnchorType>) -> NSLayoutConstraint {
        constraint(equalTo: anchor).with(priority: .streamRequire)
    }

    @objc func pin(greaterThanOrEqualTo anchor: NSLayoutAnchor<AnchorType>) -> NSLayoutConstraint {
        constraint(greaterThanOrEqualTo: anchor).with(priority: .streamRequire)
    }

    @objc func pin(lessThanOrEqualTo anchor: NSLayoutAnchor<AnchorType>) -> NSLayoutConstraint {
        constraint(lessThanOrEqualTo: anchor).with(priority: .streamRequire)
    }

    @objc func pin(equalTo anchor: NSLayoutAnchor<AnchorType>, constant c: CGFloat) -> NSLayoutConstraint {
        constraint(equalTo: anchor, constant: c).with(priority: .streamRequire)
    }

    @objc func pin(greaterThanOrEqualTo anchor: NSLayoutAnchor<AnchorType>, constant c: CGFloat) -> NSLayoutConstraint {
        constraint(greaterThanOrEqualTo: anchor, constant: c).with(priority: .streamRequire)
    }

    @objc func pin(lessThanOrEqualTo anchor: NSLayoutAnchor<AnchorType>, constant c: CGFloat) -> NSLayoutConstraint {
        constraint(lessThanOrEqualTo: anchor, constant: c).with(priority: .streamRequire)
    }
}

// This layout anchor subclass is used for sizes (width & height).

extension NSLayoutDimension {
    // These methods return an inactive constraint of the form thisVariable = constant.
    @objc func pin(equalToConstant c: CGFloat) -> NSLayoutConstraint {
        constraint(equalToConstant: c).with(priority: .streamRequire)
    }

    @objc func pin(greaterThanOrEqualToConstant c: CGFloat) -> NSLayoutConstraint {
        constraint(greaterThanOrEqualToConstant: c).with(priority: .streamRequire)
    }

    @objc func pin(lessThanOrEqualToConstant c: CGFloat) -> NSLayoutConstraint {
        constraint(lessThanOrEqualToConstant: c).with(priority: .streamRequire)
    }

    // These methods return an inactive constraint of the form thisAnchor = otherAnchor * multiplier.
    @objc func pin(equalTo anchor: NSLayoutDimension, multiplier m: CGFloat) -> NSLayoutConstraint {
        constraint(equalTo: anchor, multiplier: m).with(priority: .streamRequire)
    }

    @objc func pin(greaterThanOrEqualTo anchor: NSLayoutDimension, multiplier m: CGFloat) -> NSLayoutConstraint {
        constraint(greaterThanOrEqualTo: anchor, multiplier: m).with(priority: .streamRequire)
    }

    @objc func pin(lessThanOrEqualTo anchor: NSLayoutDimension, multiplier m: CGFloat) -> NSLayoutConstraint {
        constraint(lessThanOrEqualTo: anchor, multiplier: m).with(priority: .streamRequire)
    }

    // These methods return an inactive constraint of the form thisAnchor = otherAnchor * multiplier + constant.
    @objc func pin(equalTo anchor: NSLayoutDimension, multiplier m: CGFloat, constant c: CGFloat) -> NSLayoutConstraint {
        constraint(equalTo: anchor, multiplier: m, constant: c).with(priority: .streamRequire)
    }

    @objc func pin(
        greaterThanOrEqualTo anchor: NSLayoutDimension,
        multiplier m: CGFloat,
        constant c: CGFloat
    ) -> NSLayoutConstraint {
        constraint(greaterThanOrEqualTo: anchor, multiplier: m, constant: c).with(priority: .streamRequire)
    }

    @objc func pin(lessThanOrEqualTo anchor: NSLayoutDimension, multiplier m: CGFloat, constant c: CGFloat) -> NSLayoutConstraint {
        constraint(lessThanOrEqualTo: anchor, multiplier: m, constant: c).with(priority: .streamRequire)
    }
}

// NSLAYOUTANCHOR_H

extension NSLayoutXAxisAnchor {
    /* Constraints of the form,
     receiver [= | ≥ | ≤] 'anchor' + 'multiplier' * system space,
     where the value of the system space is determined from information available from the anchors.
     */
    @objc func pin(
        equalToSystemSpacingAfter anchor: NSLayoutXAxisAnchor,
        multiplier: CGFloat = 1
    ) -> NSLayoutConstraint {
        constraint(equalToSystemSpacingAfter: anchor, multiplier: multiplier).with(priority: .streamRequire)
    }

    @objc func pin(
        greaterThanOrEqualToSystemSpacingAfter anchor: NSLayoutXAxisAnchor,
        multiplier: CGFloat = 1
    ) -> NSLayoutConstraint {
        constraint(greaterThanOrEqualToSystemSpacingAfter: anchor, multiplier: multiplier).with(priority: .streamRequire)
    }

    @objc func pin(
        lessThanOrEqualToSystemSpacingAfter anchor: NSLayoutXAxisAnchor,
        multiplier: CGFloat = 1
    ) -> NSLayoutConstraint {
        constraint(lessThanOrEqualToSystemSpacingAfter: anchor, multiplier: multiplier).with(priority: .streamRequire)
    }
}

extension NSLayoutYAxisAnchor {
    /* Constraints of the form,
     receiver [= | ≥ | ≤] 'anchor' + 'multiplier' * system space,
     where the value of the system space is determined from information available from the anchors.
     The constraint affects how far the receiver will be positioned below 'anchor'.
     If either the receiver or 'anchor' is the firstBaselineAnchor or lastBaselineAnchor of a view with text content
     then the spacing will depend on the fonts involved and will change when those do.
     */
    @objc func pin(
        equalToSystemSpacingBelow anchor: NSLayoutYAxisAnchor,
        multiplier: CGFloat = 1
    ) -> NSLayoutConstraint {
        constraint(equalToSystemSpacingBelow: anchor, multiplier: multiplier).with(priority: .streamRequire)
    }

    @objc func pin(
        greaterThanOrEqualToSystemSpacingBelow anchor: NSLayoutYAxisAnchor,
        multiplier: CGFloat = 1
    ) -> NSLayoutConstraint {
        constraint(greaterThanOrEqualToSystemSpacingBelow: anchor, multiplier: multiplier).with(priority: .streamRequire)
    }

    @objc func pin(
        lessThanOrEqualToSystemSpacingBelow anchor: NSLayoutYAxisAnchor,
        multiplier: CGFloat = 1
    ) -> NSLayoutConstraint {
        constraint(lessThanOrEqualToSystemSpacingBelow: anchor, multiplier: multiplier).with(priority: .streamRequire)
    }
}
