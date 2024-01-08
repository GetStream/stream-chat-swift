//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// A container view that clamps its size to the size of the bigger subview, even when this subview is hidden.
open class ClampedView: _View, AppearanceProvider {
    // MARK: - UI Components

    open private(set) lazy var container: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    // MARK: - Configuration Properties

    open var axis: NSLayoutConstraint.Axis = .horizontal {
        didSet { container.axis = axis }
    }

    // MARK: - Lifecycle

    override open func setUp() {
        super.setUp()
        container.axis = axis
        container.alignment = .center
    }

    override open func setUpLayout() {
        super.setUpLayout()
        embed(container, insets: .zero)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = nil
    }

    override open var intrinsicContentSize: CGSize {
        let maxSize = CGSize(width: 0, height: bounds.height)

        let newSize = container.arrangedSubviews.reduce(maxSize) { partialResult, subview in
            let subviewSize = subview.sizeThatFits(bounds.size)
            return CGSize(width: max(partialResult.width, subviewSize.width), height: max(subviewSize.height, partialResult.height))
        }

        return newSize
    }

    // MARK: - Subviews

    open func addArrangedSubview(_ view: UIView) {
        container.addArrangedSubview(view.withoutAutoresizingMaskConstraints)
    }
}
