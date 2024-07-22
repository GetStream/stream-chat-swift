//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

// MARK: - View Container Builder

/// A result builder to create a stack view given an array of views.
/// The goal is to build UIKit layout similar to SwiftUI so that it easier to create and re-layout views.
@resultBuilder
public struct ViewContainerBuilder {
    init() {}

    public static func buildBlock(_ components: UIView?...) -> UIStackView {
        UIStackView(arrangedSubviews: components.compactMap { $0 })
    }

    public static func buildBlock(_ components: [UIView]) -> UIStackView {
        UIStackView(arrangedSubviews: components)
    }

    public static func buildEither(first component: UIStackView) -> UIStackView {
        component
    }

    public static func buildEither(second component: UIStackView) -> UIStackView {
        component
    }
}

/// The vertical container which represents a vertical `UIStackView`.
///
/// - parameter spacing: The spacing between views.
/// - parameter distribution: The stack view distribution, by default it is `.fill`.
/// - parameter alignment: The stack view alignment, by default it is `.fill`.
/// - parameter content: The result builder responsible to return the stack view with the arranged views.
public func VContainer(
    spacing: CGFloat = 0,
    distribution: UIStackView.Distribution = .fill,
    alignment: UIStackView.Alignment = .fill,
    @ViewContainerBuilder content: () -> UIStackView = { UIStackView() }
) -> UIStackView {
    let stack = content()
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .vertical
    stack.distribution = distribution
    stack.alignment = alignment
    stack.spacing = spacing
    return stack
}

/// The horizontal container which represents a horizontal `UIStackView`.
///
/// - parameter spacing: The spacing between views.
/// - parameter distribution: The stack view distribution, by default it is `.fill`.
/// - parameter alignment: The stack view alignment.
/// - parameter content: The result builder responsible to return the stack view with the arranged views.
public func HContainer(
    spacing: CGFloat = 0,
    distribution: UIStackView.Distribution = .fill,
    alignment: UIStackView.Alignment = .fill,
    @ViewContainerBuilder content: () -> UIStackView = { UIStackView() }
) -> UIStackView {
    let stack = content()
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .horizontal
    stack.distribution = distribution
    stack.alignment = alignment
    stack.spacing = spacing
    return stack
}

/// A flexible space that expands along the major axis of its containing stack layout.
public func Spacer() -> UIView {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
}

// MARK: - Layout & Constraints Builders

/// `UIView` syntax sugar to be able to set view constraints in place when building layouts with the `@ViewContainerBuilder`.
/// Example:
/// ```
/// threadIconView.constraints {
///   $0.heightAnchor.pin(equalToConstant: 15)
///   $0.widthAnchor.pin(equalToConstant: 15)
/// }
/// replyTimestampLabel.layout {
///   $0.setContentCompressionResistancePriority(.required, for: .horizontal)
/// }
/// ```
public extension UIView {
    @discardableResult
    func constraints(@LayoutBuilder block: (UIView) -> [NSLayoutConstraint]) -> UIView {
        NSLayoutConstraint.activate(block(self))
        return self
    }

    @discardableResult
    func layout(_ block: (UIView) -> Void) -> UIView {
        block(self)
        return self
    }
}

/// A result builder to be able to activate constraints given an array of constraints.
@resultBuilder
public struct LayoutBuilder {
    init() {}

    public static func buildBlock(_ components: NSLayoutConstraint...) -> [NSLayoutConstraint] {
        NSLayoutConstraint.activate(components)
        return components
    }

    public static func buildEither(first component: NSLayoutConstraint) -> [NSLayoutConstraint] {
        [component]
    }

    public static func buildEither(second component: NSLayoutConstraint) -> [NSLayoutConstraint] {
        [component]
    }
}

// MARK: - Helper to add container to parent view

public extension UIStackView {
    @discardableResult
    /// Embeds the container to the given view.
    func embed(in view: UIView) -> UIStackView {
        view.addSubview(self)
        pin(to: view)
        return self
    }

    @discardableResult
    /// Embeds the container to the given view respecting the layout margins guide.
    /// The margins can be customised by changing the `directionalLayoutMargins`.
    func embedToMargins(in view: UIView) -> UIStackView {
        view.addSubview(self)
        pin(to: view.layoutMarginsGuide)
        return self
    }
}

// MARK: - UIView width and height helpers

public extension UIView {
    /// Creates a width constraint with the given constant value.
    @discardableResult
    func width(_ value: CGFloat) -> Self {
        NSLayoutConstraint.activate([
            widthAnchor.pin(equalToConstant: value)
        ])
        return self
    }

    /// Creates a width constraint greater or equal to the given value.
    @discardableResult
    func width(greaterThanOrEqualTo value: CGFloat) -> Self {
        NSLayoutConstraint.activate([
            widthAnchor.pin(greaterThanOrEqualToConstant: value)
        ])
        return self
    }
    
    /// Creates a width constraint less or equal to the given value.
    @discardableResult
    func width(lessThanOrEqualTo value: CGFloat) -> Self {
        NSLayoutConstraint.activate([
            widthAnchor.pin(lessThanOrEqualToConstant: value)
        ])
        return self
    }
}

public extension UIView {
    /// Creates a height constraint with the given constant value.
    @discardableResult
    func height(_ value: CGFloat) -> Self {
        NSLayoutConstraint.activate([
            heightAnchor.pin(equalToConstant: value)
        ])
        return self
    }

    /// Creates a height constraint greater or equal to the given value.
    @discardableResult
    func height(greaterThanOrEqualTo value: CGFloat) -> Self {
        NSLayoutConstraint.activate([
            heightAnchor.pin(greaterThanOrEqualToConstant: value)
        ])
        return self
    }

    /// Creates a height constraint less or equal to the given value.
    @discardableResult
    func height(lessThanOrEqualTo value: CGFloat) -> Self {
        NSLayoutConstraint.activate([
            heightAnchor.pin(lessThanOrEqualToConstant: value)
        ])
        return self
    }
}
