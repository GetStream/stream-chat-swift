//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
/// View which wraps inside `SwipeActionButton` for leading layout
public class CellActionView: _View {
    /// Button wrapped inside this ActionView
    open var actionButton: UIButton = UIButton().withoutAutoresizingMaskConstraints
    /// Action which will be called on `.touchUpInside` of `actionButton`
    open var action: (() -> Void)?

    override public func setUp() {
        super.setUp()
        actionButton.addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
    }

    override public func setUpLayout() {
        super.setUpLayout()

        backgroundColor = actionButton.backgroundColor
        addSubview(actionButton)
        actionButton.pin(anchors: [.leading, .top, .bottom], to: self)
        actionButton.trailingAnchor.pin(equalTo: trailingAnchor).with(priority: .streamLow).isActive = true
        actionButton.widthAnchor.pin(equalTo: actionButton.heightAnchor).isActive = true
    }

    @objc private func touchUpInside() {
        action?()
    }
}
