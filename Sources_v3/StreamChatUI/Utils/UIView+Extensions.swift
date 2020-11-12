//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIView {
    func embed(_ subview: UIView, insets: NSDirectionalEdgeInsets = .zero) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.leading),
            subview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: insets.trailing),
            subview.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            subview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: insets.bottom)
        ])
    }
    
    func embedUsingSystemSpacing(
        _ subview: UIView,
        topInsetMultiplier: CGFloat = 1,
        bottomInsetMultiplier: CGFloat = 1,
        leadingInsetMultiplier: CGFloat = 1,
        trailingInsetMultiplier: CGFloat = 1
    ) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(
                equalToSystemSpacingBelow: topAnchor,
                multiplier: topInsetMultiplier
            ),
            subview.bottomAnchor.constraint(
                equalToSystemSpacingBelow: bottomAnchor,
                multiplier: bottomInsetMultiplier
            ),
            subview.leadingAnchor.constraint(
                equalToSystemSpacingAfter: leadingAnchor,
                multiplier: leadingInsetMultiplier
            ),
            subview.trailingAnchor.constraint(
                equalToSystemSpacingAfter: trailingAnchor,
                multiplier: trailingInsetMultiplier
            )
        ])
    }
}
