//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension ContainerStackView {
    /// Describes the size distribution of the arranged subviews in a container stack view.
    public struct Distribution: Equatable {
        /// Makes the arranged subviews with their natural size.
        public static let natural = Distribution(rawValue: 0)
        /// Makes the arranged subviews all with the same size.
        public static let equal = Distribution(rawValue: 1)

        private let rawValue: Int
    }

    /// Describes the alignment of the arranged subviews in perpendicular to the container's axis.
    public struct Alignment: Equatable {
        /// Makes the arranged subviews so that they **fill** the available space perpendicular to the container’s axis.
        public static let fill = Alignment(rawValue: 0)
        /// Makes the arranged subviews align to the **leading edge** in a **vertical axis** container.
        public static let leading = Alignment(rawValue: 1)
        /// Makes the arranged subviews align to the **top edge** in a **horizontal axis** container.
        public static let top = Alignment(rawValue: 1)
        /// Makes the arranged subviews align to the **trailing edge** in a **vertical axis** container.
        public static let trailing = Alignment(rawValue: 2)
        /// Makes the arranged subviews align to the **bottom edge** in a **horizontal axis** container.
        public static let bottom = Alignment(rawValue: 2)
        /// Makes the arranged subviews align to the **center** along its axis.
        public static let center = Alignment(rawValue: 3)

        private let rawValue: Int
    }

    /// Describes the Spacing between the arranged subviews.
    public struct Spacing: Equatable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
        /// The actual value of the Spacing.
        public var rawValue: CGFloat

        /// `Spacing` can be expressed by a `Double`.
        /// Example: `spacing = 10.0`, instead of `spacing = Spacing(10.0)`.
        public init(floatLiteral value: Double) {
            rawValue = CGFloat(value)
        }

        /// `Spacing` can be expressed by an `Int`.
        /// Example: `spacing = 10`, instead of `spacing = Spacing(10)`.
        public init(integerLiteral value: Int) {
            rawValue = CGFloat(value)
        }

        public init(_ rawValue: CGFloat) {
            self.rawValue = rawValue
        }

        /// The default system spacing between the arranged subviews.
        /// Example: `spacing = .auto`.
        public static let auto = Spacing(.infinity)
    }
}

/// A view that works similar to a `UIStackView` but in a more simpler and flexible way.
/// The aim of this view is to make UI customizability easier in the SDK.
public class ContainerStackView: UIView {
    /// The custom constraints that define the container layout. It does not include the top or leading constraints.
    private var customConstraints: [NSLayoutConstraint] = []

    /// The top anchor constraints of the layout. It is separate from `customConstraints` because
    /// these should be deactivated and activated dependent if the view is hidden/shown.
    private var customTopConstraintsByView: [UIView: NSLayoutConstraint] = [:]

    /// The leading anchor constraints of the layout. It is separate from `customConstraints` because
    /// these should be deactivated and activated dependent if the view is hidden/shown.
    private var customLeadingConstraintsByView: [UIView: NSLayoutConstraint] = [:]

    /// The custom spacing after the provided view.
    private var customSpacingByView: [UIView: CGFloat] = [:]

    /// The constraints that define the spacing between each view.
    private var spacingConstraintsByView: [UIView: NSLayoutConstraint] = [:]

    /// Each view's option if it should respect the layout margins or not.
    private var respectsLayoutMarginsByView: [UIView: Bool] = [:]

    /// Additional constraints that should be activated when a view is hidden.
    private var hideConstraintsByView: [UIView: NSLayoutConstraint] = [:]

    /// Each view's `isHidden` property is observed to hide or show the view in the container.
    private var hidingObserversByView: [UIView: NSKeyValueObservation] = [:]
    
    /// Layout guide used to enforce views having the same width/height if necessary.
    private lazy var sizeLayoutGuide = UILayoutGuide()
    
    /// Constraints that force views to be the same size on the axis, if not hidden.
    private var sizeConstraintsByView: [UIView: NSLayoutConstraint] = [:]

    /// Creates the container with predefined configuration and initial arranged subviews.
    /// - Parameters:
    ///   - axis: The axis where the arranged subviews are rendered.
    ///   - alignment: The alignment of the arranged subviews perpendicular to the container’s axis.
    ///   - spacing: The spacing between each arranged subview.
    ///   - distribution: The distribution of the arranged subviews along the container’s axis.
    ///   - arrangedSubviews: The initial arranged subviews.
    public convenience init(
        axis: NSLayoutConstraint.Axis = .horizontal,
        alignment: Alignment = .fill,
        spacing: Spacing = .auto,
        distribution: Distribution = .natural,
        arrangedSubviews: [UIView] = []
    ) {
        self.init()
        self.axis = axis
        self.alignment = alignment
        self.spacing = spacing
        self.distribution = distribution
        addArrangedSubviews(arrangedSubviews)
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)

        addLayoutGuide(sizeLayoutGuide)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// The distribution of the arranged subviews along the container’s axis.
    public var distribution: Distribution = .natural {
        didSet {
            invalidateConstraints()
        }
    }

    /// The alignment of the arranged subviews perpendicular to the container’s axis.
    public var alignment: Alignment = .fill {
        didSet {
            invalidateConstraints()
        }
    }

    /// The axis where the arranged subviews are rendered.
    public var axis: NSLayoutConstraint.Axis = .horizontal

    /// The spacing between each arranged subview.
    public var spacing: Spacing = .auto {
        didSet {
            invalidateConstraints()
        }
    }

    /// A Boolean value that determines whether the container stack view
    /// lays out its arranged subviews relative to its layout margins.
    public var isLayoutMarginsRelativeArrangement = false {
        didSet {
            invalidateConstraints()
        }
    }

    /// Replaces all of the current arranged subviews.
    /// - Parameter subviews: The new arranged subviews.
    public func replaceArrangedSubviews(with subviews: [UIView]) {
        removeAllArrangedSubviews()
        addArrangedSubviews(subviews)
    }

    /// Adds a collection of subviews to the current arranged subviews.
    /// If there are already arranged subviews, this will not replace the old ones.
    /// - Parameter subviews: The collection of subviews to be added to the arranged subviews.
    public func addArrangedSubviews(_ subviews: [UIView]) {
        subviews.forEach { addArrangedSubview($0) }
    }

    /// Adds an arranged subview to the container in the last position.
    /// - Parameters:
    ///   - subview: The subview to be added.
    ///   - respectsLayoutMargins: A Boolean value that determines if the subview should preserve it's layout margins.
    public func addArrangedSubview(_ subview: UIView, respectsLayoutMargins: Bool? = nil) {
        insertArrangedSubview(subview, at: subviews.count, respectsLayoutMargins: respectsLayoutMargins)
    }

    /// Adds an arranged subview to the container in the provided index.
    /// - Parameters:
    ///   - subview: The subview to be added.
    ///   - index: The position where the subview will be added in the arranged subviews.
    ///   - respectsLayoutMargins: A Boolean value that determines if the subview should preserve it's layout margins.
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

    /// Removes all arranged subviews from the container.
    public func removeAllArrangedSubviews() {
        subviews.forEach { removeArrangedSubview($0) }
    }

    /// Removes an arranged subview from the container.
    /// - Parameter subview: The subview to be removed.
    public func removeArrangedSubview(_ subview: UIView) {
        guard subviews.contains(subview) else {
            log.warning(
                "Trying to remove subview \(subview) from ContainerStackView \(self)"
                    + " but it wasn't added as a subview."
            )
            return
        }
        
        subview.removeFromSuperview()

        // Reset hiding state from the removed view. This important especially if the view
        // is added to another container, since the view will have the size to 0 and the other
        // container won't be able to hide the view because it thinks it is already hidden.
        subview.alpha = 1.0
        hideConstraintsByView[subview]?.isActive = false
        hideConstraintsByView[subview] = nil
        
        sizeConstraintsByView[subview]?.isActive = false
        sizeConstraintsByView[subview] = nil

        // Remove the hiding observer from the removed view
        hidingObserversByView[subview] = nil

        invalidateConstraints()
    }

    /// Changes the spacing after a specific view.
    /// - Parameters:
    ///   - spacing: The value of the spacing.
    ///   - subview: The subview that the spacing will be applied (after this subview).
    func setCustomSpacing(_ spacing: Spacing, after subview: UIView) {
        guard subviews.contains(subview) else {
            log.warning(
                "Trying to set custom spacing after subview \(subview) in ContainerStackView \(self)"
                    + " but it wasn't added as a subview."
            )
            return
        }
        
        customSpacingByView[subview] = spacing.rawValue
        invalidateConstraints()
    }

    /// The updateConstraints is overridden so we can re-layout the constraints whenever the layout is invalidated.
    override public func updateConstraints() {
        defer { super.updateConstraints() }

        // Update custom constraints only if they were explicitly invalidated
        guard customConstraints.isEmpty else { return }

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

        if alignment != .fill {
            // For the containers where subview anchors are not `=` to its layout guide (but are `>=` or `<=`)
            // we set low priority size constraint. The layout engine will try to minimise errors for those constraints.
            // As a result, the container will be the smallest possible that fits the content.
            customConstraints += [
                widthAnchor.constraint(equalToConstant: 0).with(priority: .init(1)),
                heightAnchor.constraint(equalToConstant: 0).with(priority: .init(1))
            ]
        }

        // Create spacing constraints between the arranged subviews
        zip(subviews, subviews.dropFirst()).forEach { lView, rView in
            let spacingConstraint: NSLayoutConstraint

            if axis == .horizontal {
                if let customSpacing = customSpacingByView[lView] {
                    spacingConstraint = rView.leadingAnchor.constraint(
                        equalTo: lView.trailingAnchor,
                        constant: customSpacing
                    )
                } else if spacing != .auto {
                    spacingConstraint = rView.leadingAnchor.constraint(equalTo: lView.trailingAnchor, constant: spacing.rawValue)
                } else {
                    spacingConstraint = rView.leadingAnchor.constraint(
                        equalToSystemSpacingAfter: lView.trailingAnchor,
                        multiplier: 1
                    )
                }

            } else {
                if let customSpacing = customSpacingByView[lView] {
                    spacingConstraint = rView.topAnchor.constraint(
                        equalTo: lView.bottomAnchor,
                        constant: customSpacing
                    )
                } else if spacing != .auto {
                    spacingConstraint = rView.topAnchor.constraint(equalTo: lView.bottomAnchor, constant: spacing.rawValue)
                } else {
                    spacingConstraint = rView.topAnchor.constraint(equalToSystemSpacingBelow: lView.bottomAnchor, multiplier: 1)
                }
            }

            spacingConstraintsByView[lView] = spacingConstraint
            spacingConstraintsByView[rView] = spacingConstraint
            customConstraints.append(spacingConstraint)
        }

        // Make the arranged subviews all with the same size in case of equal distribution
        if distribution == .equal {
            subviews.forEach { view in
                if axis == .horizontal {
                    sizeConstraintsByView[view] = view.widthAnchor.constraint(equalTo: sizeLayoutGuide.widthAnchor)
                } else {
                    sizeConstraintsByView[view] = view.heightAnchor.constraint(equalTo: sizeLayoutGuide.heightAnchor)
                }
            }
        }

        // Add constraints for the layout alignment.
        subviews.forEach { subview in
            if axis == .horizontal {
                if alignment == .leading || alignment == .fill {
                    let constraint = guide(for: subview).topAnchor.constraint(equalTo: subview.topAnchor)
                    customTopConstraintsByView[subview] = constraint
                } else {
                    let constraint = guide(for: subview).topAnchor.constraint(lessThanOrEqualTo: subview.topAnchor)
                    customTopConstraintsByView[subview] = constraint
                }

                if alignment == .trailing || alignment == .fill {
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
                if alignment == .leading || alignment == .fill {
                    let constraint = guide(for: subview).leadingAnchor.constraint(equalTo: subview.leadingAnchor)
                    customLeadingConstraintsByView[subview] = constraint
                } else {
                    let constraint = guide(for: subview).leadingAnchor.constraint(lessThanOrEqualTo: subview.leadingAnchor)
                    customLeadingConstraintsByView[subview] = constraint
                }

                if alignment == .trailing || alignment == .fill {
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
        
        for (view, constraint) in sizeConstraintsByView where !view.isHidden {
            constraint.isActive = true
        }
    }

    // MARK: - Private API

    /// Invalidates the current layout constraints.
    private func invalidateConstraints() {
        NSLayoutConstraint.deactivate(customConstraints)
        NSLayoutConstraint.deactivate(customTopConstraintsByView.map(\.value))
        NSLayoutConstraint.deactivate(customLeadingConstraintsByView.map(\.value))
        NSLayoutConstraint.deactivate(sizeConstraintsByView.map(\.value))
        customConstraints = []
        customTopConstraintsByView = [:]
        customLeadingConstraintsByView = [:]
        sizeConstraintsByView = [:]
        setNeedsUpdateConstraints()
    }

    /// Returns the layout guide the arranged subview should respect.
    private func guide(for subview: UIView) -> UILayoutGuide {
        respectsLayoutMarginsByView[subview] ?? isLayoutMarginsRelativeArrangement
            ? layoutMarginsGuide
            : safeAreaLayoutGuide
    }

    /// Hides the arranged subview by setting the width, height and spacing constraints to 0.
    private func hideArrangedSubview(_ subview: UIView) {
        guard subviews.contains(subview) else { return }
        guard subview.alpha != 0 else { return }

        updateConstraintsIfNeeded()
        
        sizeConstraintsByView[subview]?.isActive = false

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

        setNeedsLayout()
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
        
        sizeConstraintsByView[subview]?.isActive = true

        spacingConstraintsByView[subview]?.resetTemporaryConstant()
        
        setNeedsLayout()
    }

    deinit {
        hidingObserversByView = [:]
    }
}

// MARK: - UIKit Extension Helpers

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

extension NSLayoutConstraint {
    func setTemporaryConstant(_ value: CGFloat) {
        guard originalConstant == nil else { return }
        originalConstant = constant
        constant = value
    }

    func resetTemporaryConstant() {
        if let original = originalConstant {
            constant = original
            originalConstant = nil
        }
    }

    static var originalConstantKey: UInt8 = 0

    private var originalConstant: CGFloat? {
        get { objc_getAssociatedObject(self, &Self.originalConstantKey) as? CGFloat }
        set { objc_setAssociatedObject(self, &Self.originalConstantKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
