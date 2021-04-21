//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIView {
    func flexible(axis: NSLayoutConstraint.Axis) -> Self {
        setContentHuggingPriority(.lowest, for: axis)
        return self
    }
}

extension NSLayoutConstraint {
    func priority(_ p: UILayoutPriority) -> Self {
        priority = p
        return self
    }

    func priority(_ p: Float) -> Self {
        priority = UILayoutPriority(p)
        return self
    }
}

extension UILayoutPriority {
    static let lowest = UILayoutPriority(defaultLow.rawValue / 2.0)
}

extension CGFloat {
    public static let auto: CGFloat = .infinity
}

public class ContainerStackView: UIView {
    private var hidingObserversByView: [UIView: NSKeyValueObservation] = [:]
    public convenience init(
        axis: NSLayoutConstraint.Axis = .horizontal,
        alignment: Alignment = .fill,
        spacing: CGFloat = .auto,
        views: [UIView] = []
    ) {
        self.init()
        self.axis = axis
        self.alignment = alignment
        self.spacing = spacing
        views.forEach { addArrangedSubview($0) }
    }

    public struct Distribution: Equatable {
        public static let natural = Distribution(rawValue: 0)
        public static let equal = Distribution(rawValue: 1)

        private let rawValue: Int
    }

    public var distribution: Distribution = .natural {
        didSet {
            invalidateConstraints()
        }
    }

    public struct Alignment: Equatable {
        public static let fill = Alignment(rawValue: 0)
        public static let axisLeading = Alignment(rawValue: 1)
        public static let axisTrailing = Alignment(rawValue: 2)
        public static let center = Alignment(rawValue: 3)

        private let rawValue: Int
    }

    public var alignment: Alignment = .fill {
        didSet {
            invalidateConstraints()
        }
    }

    public struct Ordering: Equatable {
        static let leadingToTrailing = Ordering(rawValue: 0)
        static let trailingToLeading = Ordering(rawValue: 1)
        private let rawValue: Int
    }

    var ordering: Ordering = .leadingToTrailing {
        didSet {
            invalidateConstraints()
        }
    }

    public var isLayoutMarginsRelativeArrangement = false {
        didSet {
            invalidateConstraints()
        }
    }

    public var axis: NSLayoutConstraint.Axis = .horizontal
    public var spacing: CGFloat = .auto {
        didSet {
            invalidateConstraints()
        }
    }

    func setCustomSpacing(_ spacing: CGFloat, after subview: UIView) {
        assert(subviews.contains(subview))
        customSpacingByView[subview] = spacing
        invalidateConstraints()
    }

    public func insertArrangedSubview(_ subview: UIView, at index: Int, respectsLayoutMargins: Bool? = nil) {
        insertSubview(subview, at: index)
        subview.translatesAutoresizingMaskIntoConstraints = false
        if let respectsLayoutMargins = respectsLayoutMargins {
            respectsLayoutMarginsByView[subview] = respectsLayoutMargins
        } else {
            respectsLayoutMarginsByView.removeValue(forKey: subview)
        }

        hidingObserversByView[subview] = subview
            .observe(\.isHidden, options: [.new]) { [weak self] (view, isHiddenChange) in
                if isHiddenChange.newValue == true {
                    self?.hideArrangedSubview(view)
                } else {
                    self?.showArrangedSubview(view)
                }
            }

        invalidateConstraints()
    }

    /// Removes an arranged subview from the container.
    /// - Parameter subview: The subview to be removed.
    public func removeArrangedSubview(_ subview: UIView) {
        assert(subviews.contains(subview))
        subview.removeFromSuperview()

        hidingObserversByView[subview] = nil

        invalidateConstraints()
    }

    private func invalidateConstraints() {
        NSLayoutConstraint.deactivate(customConstraints)
        NSLayoutConstraint.deactivate(customTopConstraintsByView.map(\.value))
        NSLayoutConstraint.deactivate(customLeadingConstraintsByView.map(\.value))
        customConstraints = []
        customTopConstraintsByView = [:]
        customLeadingConstraintsByView = [:]
        setNeedsUpdateConstraints()
    }

    override public func updateConstraints() {
        defer { super.updateConstraints() }

        // Update custom constraints only if they were explicitly invalidated
        guard customConstraints.isEmpty else { return }

        let subviews = ordering == .leadingToTrailing ? self.subviews : self.subviews.reversed()

        // Check if we have at least one subview
        guard let firstSubview = subviews.first, let lastSubview = subviews.last else { return }

        // Set leading and trailing constraints for the first and last subview
        if axis == .horizontal {
            customConstraints.append(contentsOf: [
                guide(for: firstSubview).leadingAnchor.constraint(equalTo: firstSubview.leadingAnchor),
                guide(for: lastSubview).trailingAnchor.constraint(equalTo: lastSubview.trailingAnchor)
            ])
        } else {
            customConstraints.append(contentsOf: [
                guide(for: firstSubview).topAnchor.constraint(equalTo: firstSubview.topAnchor),
                guide(for: lastSubview).bottomAnchor.constraint(equalTo: lastSubview.bottomAnchor)
            ])
        }

        // Create spacing constraints between subviews
        zip(subviews, subviews.dropFirst()).forEach { lView, rView in
            let spacingConstraint: NSLayoutConstraint

            if axis == .horizontal {
                if let customSpacing = customSpacingByView[ordering == .leadingToTrailing ? lView : rView] {
                    spacingConstraint = rView.leadingAnchor.constraint(
                        equalTo: lView.trailingAnchor,
                        constant: customSpacing
                    )
                } else if spacing != .auto {
                    spacingConstraint = rView.leadingAnchor.constraint(equalTo: lView.trailingAnchor, constant: spacing)
                } else {
                    spacingConstraint = rView.leadingAnchor.constraint(
                        equalToSystemSpacingAfter: lView.trailingAnchor,
                        multiplier: 1
                    )
                }

            } else {
                if let customSpacing = customSpacingByView[ordering == .leadingToTrailing ? lView : rView] {
                    spacingConstraint = rView.topAnchor.constraint(
                        equalTo: lView.bottomAnchor,
                        constant: customSpacing
                    )
                } else if spacing != .auto {
                    spacingConstraint = rView.topAnchor.constraint(equalTo: lView.bottomAnchor, constant: spacing)
                } else {
                    spacingConstraint = rView.topAnchor.constraint(equalToSystemSpacingBelow: lView.bottomAnchor, multiplier: 1)
                }
            }

            spacingConstraintsByView[lView] = spacingConstraint
            spacingConstraintsByView[rView] = spacingConstraint
            customConstraints.append(spacingConstraint)
        }

        if distribution == .equal {
            zip(subviews, subviews.dropFirst()).forEach { lView, rView in
                if axis == .horizontal {
                    customConstraints.append(
                        lView.widthAnchor.constraint(equalTo: rView.widthAnchor)
                    )
                } else {
                    customConstraints.append(
                        lView.heightAnchor.constraint(equalTo: rView.heightAnchor)
                    )
                }
            }
        }

        subviews.forEach { subview in

            if axis == .horizontal {
                if alignment == .axisLeading || alignment == .fill {
                    let constraint = guide(for: subview).topAnchor.constraint(equalTo: subview.topAnchor)
                    customTopConstraintsByView[subview] = constraint
                } else {
                    let constraint = guide(for: subview).topAnchor.constraint(lessThanOrEqualTo: subview.topAnchor)
                    customTopConstraintsByView[subview] = constraint
                }

                if alignment == .axisTrailing || alignment == .fill {
                    let constraint = guide(for: subview).bottomAnchor.constraint(equalTo: subview.bottomAnchor)
                    customConstraints.append(constraint)
                } else {
                    let constraint = guide(for: subview).bottomAnchor.constraint(greaterThanOrEqualTo: subview.bottomAnchor)
                    customConstraints.append(constraint)
                }

                if alignment == .center {
                    customConstraints.append(guide(for: subview).centerYAnchor.constraint(equalTo: subview.centerYAnchor))
                }
            } else {
                if alignment == .axisLeading || alignment == .fill {
                    let constraint = guide(for: subview).leadingAnchor.constraint(equalTo: subview.leadingAnchor)
                    customLeadingConstraintsByView[subview] = constraint
                } else {
                    let constraint = guide(for: subview).leadingAnchor.constraint(lessThanOrEqualTo: subview.leadingAnchor)
                    customLeadingConstraintsByView[subview] = constraint
                }

                if alignment == .axisTrailing || alignment == .fill {
                    let constraint = guide(for: subview).trailingAnchor.constraint(equalTo: subview.trailingAnchor)
                    customConstraints.append(constraint)
                } else {
                    let constraint = guide(for: subview).trailingAnchor.constraint(greaterThanOrEqualTo: subview.trailingAnchor)
                    customConstraints.append(constraint)
                }

                if alignment == .center {
                    customConstraints.append(guide(for: subview).centerXAnchor.constraint(equalTo: subview.centerXAnchor))
                }
            }
        }

        customConstraints.forEach {
            $0.isActive = true
        }

        for (view, constraint) in customLeadingConstraintsByView where !view.isHidden {
            constraint.isActive = true
        }

        for (view, constraint) in customTopConstraintsByView where !view.isHidden {
            constraint.isActive = true
        }
    }

    private var customConstraints: [NSLayoutConstraint] = []

    private var customSpacingByView: [UIView: CGFloat] = [:]

    private var customTopConstraintsByView: [UIView: NSLayoutConstraint] = [:]

    private var customLeadingConstraintsByView: [UIView: NSLayoutConstraint] = [:]

    /// The constraint for axis-trailing spacing for the given vies
    private var spacingConstraintsByView: [UIView: NSLayoutConstraint] = [:]

    private var hideConstraintsByView: [UIView: NSLayoutConstraint] = [:]

    private var respectsLayoutMarginsByView: [UIView: Bool] = [:]

    /// Returns the layout guide the subview should respect
    private func guide(for subview: UIView) -> UILayoutGuide {
        respectsLayoutMarginsByView[subview] ?? isLayoutMarginsRelativeArrangement
            ? layoutMarginsGuide
            : safeAreaLayoutGuide
    }

    public func addArrangedSubview(_ builder: () -> UIView) {
        addArrangedSubview(builder())
    }

    public func addArrangedSubviews(_ subviews: [UIView]) {
        subviews.forEach { addArrangedSubview($0) }
    }

    /// Hides the arranged subview by setting the width, height and spacing constraints to 0.
    private func hideArrangedSubview(_ subview: UIView) {
        guard subviews.contains(subview) else { return }
        guard subview.alpha != 0 else { return }

        updateConstraintsIfNeeded()

        if axis == .horizontal {
            hideConstraintsByView[subview] = subview.widthAnchor.constraint(equalToConstant: 0)
        } else {
            hideConstraintsByView[subview] = subview.heightAnchor.constraint(equalToConstant: 0)
        }

        subview.alpha = 0

        if axis == .horizontal {
            customTopConstraintsByView[subview]?.isActive = false
        } else {
            customLeadingConstraintsByView[subview]?.isActive = false
        }

        hideConstraintsByView[subview]?.isActive = true

        spacingConstraintsByView[subview]?.setTemporaryConstant(0)

        layoutIfNeeded()
    }

    /// Shows the arranged subview by setting the width, height and spacing constraints to the original value before being hidden.
    private func showArrangedSubview(_ subview: UIView) {
        guard subviews.contains(subview) else { return }
        guard subview.alpha == 0 else { return }

        updateConstraintsIfNeeded()

        subview.alpha = 1

        if axis == .horizontal {
            customTopConstraintsByView[subview]?.isActive = true
        } else {
            customLeadingConstraintsByView[subview]?.isActive = true
        }

        hideConstraintsByView[subview]?.isActive = false

        spacingConstraintsByView[subview]?.resetTemporaryConstant()
        layoutIfNeeded()
    }

    deinit {
        hidingObserversByView = [:]
    }
}

extension NSLayoutConstraint {
    func setTemporaryConstant(_ value: CGFloat) {
        originalConstant = constant
        constant = value
    }

    func resetTemporaryConstant() {
        if let original = originalConstant {
            constant = original
        }
    }

    static var originalConstantKey: UInt8 = 0

    private var originalConstant: CGFloat? {
        get { objc_getAssociatedObject(self, &Self.originalConstantKey) as? CGFloat }
        set { objc_setAssociatedObject(self, &Self.originalConstantKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
