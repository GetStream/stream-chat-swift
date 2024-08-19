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

    /// A block responsible to support if-statements when building the stack views.
    public static func buildEither(first component: UIStackView) -> UIStackView {
        component
    }

    /// A block responsible to support if-statements when building the stack views.
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
    let view = UIStackView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
}

// MARK: - Layout & Constraints Builders

public extension UIView {
    /// Syntax sugar to be able to add additional layout changes in place when building layouts with the `@ViewContainerBuilder`.
    /// Example:
    /// ```
    /// replyTimestampLabel.layout {
    ///   $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    ///
    ///   NSLayoutConstraint.activate([
    ///     $0.heightAnchor.pin(equalToConstant: 15)
    ///     $0.widthAnchor.pin(equalToConstant: 15)
    ///   ])
    /// }
    /// ```
    @discardableResult
    func layout(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }

    /// Syntax sugar to be able to set view constraints in place when building layouts with the `@ViewContainerBuilder`.
    /// The constraints are automatically activated.
    ///
    /// Example:
    /// ```
    /// threadIconView.constraints {
    ///   $0.heightAnchor.pin(equalToConstant: 15)
    ///   $0.widthAnchor.pin(equalToConstant: 15)
    /// }
    /// ```
    @discardableResult
    func constraints(@ViewContainerBuilder block: (Self) -> [NSLayoutConstraint]) -> Self {
        NSLayoutConstraint.activate(block(self))
        return self
    }
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
