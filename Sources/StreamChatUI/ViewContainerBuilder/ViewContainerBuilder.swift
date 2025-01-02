//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import UIKit

// MARK: - View Container Builder

/// A result builder to create a stack view given an array of views.
/// The goal is to build UIKit layout similar to SwiftUI so that it easier to create and re-layout views.
@resultBuilder
public struct ViewContainerBuilder {
    init() {}

    /// The block responsible to produce a UIStackView given multiple views.
    /// Example:
    /// ```
    /// HContainer {
    ///     threadIconView
    ///     replyTimestampLabel
    /// }
    /// ```
    public static func buildBlock(_ components: UIView?...) -> UIStackView {
        UIStackView(arrangedSubviews: components.compactMap { $0 })
    }

    /// The block responsible to produce a UIStackView given an array views.
    /// Example:
    /// ```
    /// HContainer {
    ///     headerViews // -> [UIView]
    /// }
    /// ```
    public static func buildBlock(_ components: [UIView]) -> UIStackView {
        UIStackView(arrangedSubviews: components)
    }

    /// The block responsible to replace the views of a stack view.
    /// Example:
    /// ```
    /// container.views {
    ///     threadIconView
    ///     replyTimestampLabel
    /// }
    /// ```
    public static func buildBlock(_ components: UIView?...) -> [UIView] {
        components.compactMap { $0 }
    }

    /// The block responsible to help creating additional constraints in a container.
    /// Example:
    /// ```
    /// threadIconView.constraints {
    ///   $0.heightAnchor.pin(equalToConstant: 15)
    ///   $0.widthAnchor.pin(equalToConstant: 15)
    /// }
    /// ```
    public static func buildBlock(_ components: NSLayoutConstraint...) -> [NSLayoutConstraint] {
        NSLayoutConstraint.activate(components)
        return components
    }
    
    /// A block responsible to support if-statements.
    public static func buildOptional(_ component: UIView?) -> UIView? {
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
    let view = UIStackView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
}

// MARK: - UIStackView.views {} - Helper to replace the subviews

public extension UIStackView {
    /// Result builder to allow replacing views of a container.
    /// This is useful when containers have a reference.
    ///
    /// /// Example:
    /// ```
    /// container.views {
    ///     threadIconView
    ///     replyTimestampLabel
    /// }
    /// ```
    @discardableResult
    func views(
        @ViewContainerBuilder _ subviews: () -> [UIView]
    ) -> Self {
        removeAllArrangedSubviews()
        subviews().forEach { addArrangedSubview($0) }
        return self
    }
}

// MARK: - UIStackView.padding()

public extension UIStackView {
    /// Adds padding to the stack view. Internally is uses `isLayoutMarginsRelativeArrangement`.
    /// - Parameter value: The value to apply the padding to all edges.
    @discardableResult
    func padding(_ value: CGFloat = 8) -> UIStackView {
        isLayoutMarginsRelativeArrangement = true
        directionalLayoutMargins = .init(
            top: value,
            leading: value,
            bottom: value,
            trailing: value
        )
        return self
    }

    /// Adds padding to the stack view. Internally is uses `isLayoutMarginsRelativeArrangement`.
    /// - Parameters:
    ///   - top: The padding value at the top.
    ///   - leading: The padding value at the leading edge.
    ///   - bottom: The padding value at the bottom edge.
    ///   - trailing: The padding value at the trailing edge.
    @discardableResult
    func padding(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) -> UIStackView {
        isLayoutMarginsRelativeArrangement = true
        directionalLayoutMargins = .init(
            top: top,
            leading: leading,
            bottom: bottom,
            trailing: trailing
        )
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

// MARK: - UIStackView.embed() - Helper to add container to parent view

public extension UIStackView {
    /// Embeds the container to the given view.
    @discardableResult
    func embed(in view: UIView) -> UIStackView {
        view.addSubview(self)
        pin(to: view)
        return self
    }

    /// Embeds the container to the given view with insets.
    @discardableResult
    func embed(in view: UIView, insets: NSDirectionalEdgeInsets) -> UIStackView {
        view.embed(self, insets: insets)
        return self
    }

    /// Embeds the container to the given view respecting the layout margins guide.
    /// The margins can be customised by changing the `directionalLayoutMargins`.
    @discardableResult
    func embedToMargins(in view: UIView) -> UIStackView {
        view.addSubview(self)
        pin(to: view.layoutMarginsGuide)
        return self
    }
}
