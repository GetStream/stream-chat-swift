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
    static let auto: CGFloat = .infinity
}

public class ContainerView: UIView {
    convenience init(
        axis: NSLayoutConstraint.Axis = .horizontal,
        alignment: Alignment = .fill,
        views: [UIView] = [],
        spacing: CGFloat = .auto
    ) {
        self.init()
        self.axis = axis
        self.alignment = alignment
        self.spacing = spacing
        views.forEach { addArrangedSubview($0) }
    }
    
    struct Distribution: Equatable {
        static let natural = Distribution(rawValue: 0)
        static let equal = Distribution(rawValue: 1)

        private let rawValue: Int
    }
    
    var distribution: Distribution = .natural {
        didSet {
            invalidateConstraints()
        }
    }

    struct Alignment: Equatable {
        static let fill = Alignment(rawValue: 0)
        static let axisLeading = Alignment(rawValue: 1)
        static let axisTrailing = Alignment(rawValue: 2)
        static let center = Alignment(rawValue: 3)
        
        private let rawValue: Int
    }
    
    var alignment: Alignment = .fill {
        didSet {
            invalidateConstraints()
        }
    }

    struct Ordering: Equatable {
        static let leadingToTrailing = Ordering(rawValue: 0)
        static let trailingToLeading = Ordering(rawValue: 1)
        private let rawValue: Int
    }
    
    var ordering: Ordering = .leadingToTrailing {
        didSet {
            invalidateConstraints()
        }
    }

    var isLayoutMarginsRelativeArrangement = false {
        didSet {
            invalidateConstraints()
        }
    }
    
    var axis: NSLayoutConstraint.Axis = .horizontal
    var spacing: CGFloat = .auto {
        didSet {
            invalidateConstraints()
        }
    }

    func setCustomSpacing(_ spacing: CGFloat, after subview: UIView) {
        assert(subviews.contains(subview))
        customSpacingByView[subview] = spacing
        invalidateConstraints()
    }
    
    func insertArrangedSubview(_ subview: UIView, at index: Int, respectsLayoutMargins: Bool? = nil) {
        insertSubview(subview, at: index)
        subview.translatesAutoresizingMaskIntoConstraints = false
        if let respectsLayoutMargins = respectsLayoutMargins {
            respectsLayoutMarginsByView[subview] = respectsLayoutMargins
        } else {
            respectsLayoutMarginsByView.removeValue(forKey: subview)
        }
        
        invalidateConstraints()
    }
    
    func removeArrangedSubview(_ subview: UIView) {
        assert(subviews.contains(subview))
        subview.removeFromSuperview()
        invalidateConstraints()
    }
    
    func addArrangedSubview(_ subview: UIView, respectsLayoutMargins: Bool? = nil) {
        insertArrangedSubview(subview, at: subviews.count, respectsLayoutMargins: respectsLayoutMargins)
    }
    
    private func invalidateConstraints() {
        NSLayoutConstraint.deactivate(customConstraints)
        customConstraints = []
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
            customConstraints.append(spacingConstraint)
        }
        
        // Add constraints for distribution
        zip(subviews, subviews.dropFirst()).forEach { lView, rView in
            if axis == .horizontal {
                customConstraints.append(
                    lView.widthAnchor.constraint(equalTo: rView.widthAnchor).priority(distribution == .equal ? .required : .lowest)
                )
            } else {
                customConstraints.append(
                    lView.heightAnchor.constraint(equalTo: rView.heightAnchor)
                        .priority(distribution == .equal ? .required : .lowest)
                )
            }
        }
        
        subviews.forEach { subview in
                        
            if axis == .horizontal {
                if alignment == .axisLeading || alignment == .fill {
                    customConstraints.append(guide(for: subview).topAnchor.constraint(equalTo: subview.topAnchor))
                } else {
                    customConstraints.append(guide(for: subview).topAnchor.constraint(lessThanOrEqualTo: subview.topAnchor))
                }

                if alignment == .axisTrailing || alignment == .fill {
                    customConstraints.append(guide(for: subview).bottomAnchor.constraint(equalTo: subview.bottomAnchor))
                } else {
                    customConstraints
                        .append(guide(for: subview).bottomAnchor.constraint(greaterThanOrEqualTo: subview.bottomAnchor))
                }
                
                if alignment == .center {
                    customConstraints.append(guide(for: subview).centerYAnchor.constraint(equalTo: subview.centerYAnchor))
                }
            } else {
                if alignment == .axisLeading || alignment == .fill {
                    customConstraints.append(guide(for: subview).leadingAnchor.constraint(equalTo: subview.leadingAnchor))
                } else {
                    customConstraints.append(guide(for: subview).leadingAnchor.constraint(lessThanOrEqualTo: subview.leadingAnchor))
                }

                if alignment == .axisTrailing || alignment == .fill {
                    customConstraints.append(guide(for: subview).trailingAnchor.constraint(equalTo: subview.trailingAnchor))
                } else {
                    customConstraints
                        .append(guide(for: subview).trailingAnchor.constraint(greaterThanOrEqualTo: subview.trailingAnchor))
                }
                
                if alignment == .center {
                    customConstraints.append(guide(for: subview).centerXAnchor.constraint(equalTo: subview.centerXAnchor))
                }
            }
        }

        customConstraints.forEach {
            $0.isActive = true
        }
    }
    
    private var customConstraints: [NSLayoutConstraint] = []

    private var customSpacingByView: [UIView: CGFloat] = [:]
    
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
    
    func addArrangedSubview(_ builder: () -> UIView) {
        addArrangedSubview(builder())
    }

    func hideSubview(_ subview: UIView, animated: Bool = true) {
        assert(subviews.contains(subview))

        hideConstraintsByView[subview] = subview.heightAnchor.constraint(equalToConstant: 0)

        Animate(isAnimated: animated) {
            subview.alpha = 0
            self.hideConstraintsByView[subview]?.isActive = true
            self.spacingConstraintsByView[subview]?.setTemporaryConstant(0)
            self.layoutIfNeeded()
        }
    }
    
    func showSubview(_ subview: UIView, animated: Bool = true) {
        assert(subviews.contains(subview))

        Animate(isAnimated: animated) {
            subview.alpha = 1
            self.hideConstraintsByView[subview]?.isActive = false
            self.spacingConstraintsByView[subview]?.resetTemporaryConstant()
            self.layoutIfNeeded()
        }
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
