//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

// Protocol that provides accessibility features
protocol AccessibilityView {
    // Identifier for view
    var accessibilityViewIdentifier: String { get }

    // This function is called once the view is being added to the view hiearchy
    func setAccessibilityIdentifier()
}

extension AccessibilityView where Self: UIView {
    var accessibilityViewIdentifier: String {
        "\(type(of: self))"
    }

    func setAccessibilityIdentifier() {
        accessibilityIdentifier = accessibilityViewIdentifier
    }
}

/// Property wrapper that allows you to set `accesibleIdentifier` on `View` that is not instantiated && not declared as `lazy`
///
/// Usage:
///     @AccessibleView(accessibilityIdentifier: "textView")
///     var textView: UITextView?
@propertyWrapper
public struct AccessibleView<T: UIView>: AccessibilityView {
    private(set) var accessibilityViewIdentifier: String

    public var wrappedValue: T? {
        didSet {
            setAccessibilityIdentifier()
        }
    }

    public init(wrappedValue: T? = nil, accessibilityIdentifier: String = "\(type(of: T.self))") {
        self.wrappedValue = wrappedValue
        accessibilityViewIdentifier = accessibilityIdentifier
        setAccessibilityIdentifier()
    }

    func setAccessibilityIdentifier() {
        wrappedValue?.accessibilityIdentifier = accessibilityViewIdentifier
    }
}

// Just a protocol to formalize the methods required
public protocol Customizable {
    /// Main point of customization for the view functionality.
    ///
    /// **It's called zero or one time(s) during the view's lifetime.** Calling super implementation is required.
    func setUp()

    /// Main point of customization for the view appearance.
    ///
    /// **It's called multiple times during the view's lifetime.** The default implementation of this method is empty
    /// so calling `super` is usually not needed.
    func setUpAppearance()

    /// Main point of customization for the view layout.
    ///
    /// **It's called zero or one time(s) during the view's lifetime.** Calling super is recommended but not required
    /// if you provide a complete layout for all subviews.
    func setUpLayout()

    /// Main point of customizing the way the view updates its content.
    ///
    /// **It's called every time view's content changes.** Calling super is recommended but not required if you update
    /// the content of all subviews of the view.
    func updateContent()
}

public extension Customizable where Self: UIView {
    /// If the view is already in the view hierarchy it calls `updateContent()`, otherwise does nothing.
    func updateContentIfNeeded() {
        if superview != nil {
            updateContent()
        }
    }
}

public extension Customizable where Self: UIViewController {
    /// If the view is already loaded it calls `updateContent()`, otherwise does nothing.
    func updateContentIfNeeded() {
        if isViewLoaded {
            updateContent()
        }
    }
}

extension ComponentsProvider where Self: _View {
    public func componentsDidRegister() {
        if isInitialized {
            log.assertionFailure(
                """
                `Components` was assigned after the view has been already initialized. \
                This is most likely caused by assigning the custom `Components` instance \
                after the view has been added to the view hierarchy, or after the view's subviews \
                have been initialized already. This is undefined behavior and should be avoided.
                """
            )
        }
    }
}

extension AppearanceProvider where Self: _View {
    public func appearanceDidRegister() {
        if isInitialized {
            log.assertionFailure(
                """
                `Appearance` was assigned after the view has been already initialized. \
                This is most likely caused by assigning the custom `Appearance` instance \
                after the view has been added to the view hierarchy, or after the view's subviews \
                have been initialized already. This is undefined behavior and should be avoided.
                """
            )
        }
    }
}

/// Base class for overridable views StreamChatUI provides.
/// All conformers will have StreamChatUI appearance settings by default.
open class _View: UIView, Customizable, AccessibilityView {
    // Flag for preventing multiple lifecycle methods calls.
    fileprivate var isInitialized: Bool = false
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard !isInitialized, superview != nil else { return }
        
        isInitialized = true

        setAccessibilityIdentifier()
        setUp()
        setUpLayout()
        setUpAppearance()
        updateContent()
    }
    
    open func setUp() { /* default empty implementation */ }
    open func setUpAppearance() { setNeedsLayout() }
    open func setUpLayout() { setNeedsLayout() }
    open func updateContent() { setNeedsLayout() }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 12, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        TraitCollectionReloadStack.push {
            self.setUpAppearance()
            self.updateContent()
        }
    }

    override open func layoutSubviews() {
        TraitCollectionReloadStack.executePendingUpdates()
        super.layoutSubviews()
    }
}

/// Base class for overridable views StreamChatUI provides.
/// All conformers will have StreamChatUI appearance settings by default.
open class _CollectionViewCell: UICollectionViewCell, Customizable, AccessibilityView {
    // Flag for preventing multiple lifecycle methods calls.
    private var isInitialized: Bool = false
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard !isInitialized, superview != nil else { return }
        
        isInitialized = true

        setAccessibilityIdentifier()
        setUp()
        setUpLayout()
        setUpAppearance()
        updateContent()
    }
    
    open func setUp() { /* default empty implementation */ }
    open func setUpAppearance() { setNeedsLayout() }
    open func setUpLayout() { setNeedsLayout() }
    open func updateContent() { setNeedsLayout() }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 12, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        TraitCollectionReloadStack.push {
            self.setUpAppearance()
            self.updateContent()
        }
    }

    override open func layoutSubviews() {
        TraitCollectionReloadStack.executePendingUpdates()
        super.layoutSubviews()
    }
}

/// Base class for overridable views StreamChatUI provides.
/// All conformers will have StreamChatUI appearance settings by default.
open class _CollectionReusableView: UICollectionReusableView, Customizable, AccessibilityView {
    // Flag for preventing multiple lifecycle methods calls.
    private var isInitialized: Bool = false

    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard !isInitialized, superview != nil else { return }

        isInitialized = true

        setAccessibilityIdentifier()
        setUp()
        setUpLayout()
        setUpAppearance()
        updateContent()
    }

    open func setUp() { /* default empty implementation */ }
    open func setUpAppearance() { setNeedsLayout() }
    open func setUpLayout() { setNeedsLayout() }
    open func updateContent() { setNeedsLayout() }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 12, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        TraitCollectionReloadStack.push {
            self.setUpAppearance()
            self.updateContent()
        }
    }

    override open func layoutSubviews() {
        TraitCollectionReloadStack.executePendingUpdates()
        super.layoutSubviews()
    }
}

/// Base class for overridable views StreamChatUI provides.
/// All conformers will have StreamChatUI appearance settings by default.
open class _Control: UIControl, Customizable, AccessibilityView {
    // Flag for preventing multiple lifecycle methods calls.
    private var isInitialized: Bool = false
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard !isInitialized, superview != nil else { return }
        
        isInitialized = true

        setAccessibilityIdentifier()
        setUp()
        setUpLayout()
        setUpAppearance()
        updateContent()
    }
    
    open func setUp() { /* default empty implementation */ }
    open func setUpAppearance() { setNeedsLayout() }
    open func setUpLayout() { setNeedsLayout() }
    open func updateContent() { setNeedsLayout() }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 12, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        TraitCollectionReloadStack.push {
            self.setUpAppearance()
            self.updateContent()
        }
    }

    override open func layoutSubviews() {
        TraitCollectionReloadStack.executePendingUpdates()
        super.layoutSubviews()
    }
}

/// Base class for overridable views StreamChatUI provides.
/// All conformers will have StreamChatUI appearance settings by default.
open class _Button: UIButton, Customizable, AccessibilityView {
    // Flag for preventing multiple lifecycle methods calls.
    private var isInitialized: Bool = false
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard !isInitialized, superview != nil else { return }
        
        isInitialized = true

        setAccessibilityIdentifier()
        setUp()
        setUpLayout()
        setUpAppearance()
        updateContent()
    }
    
    open func setUp() { /* default empty implementation */ }
    open func setUpAppearance() { setNeedsLayout() }
    open func setUpLayout() { setNeedsLayout() }
    open func updateContent() { setNeedsLayout() }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 12, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        TraitCollectionReloadStack.push {
            self.setUpAppearance()
            self.updateContent()
        }
    }

    override open func layoutSubviews() {
        TraitCollectionReloadStack.executePendingUpdates()
        super.layoutSubviews()
    }
}

/// Base class for overridable views StreamChatUI provides.
/// All conformers will have StreamChatUI appearance settings by default.
open class _NavigationBar: UINavigationBar, Customizable, AccessibilityView {
    // Flag for preventing multiple lifecycle methods calls.
    private var isInitialized: Bool = false
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard !isInitialized, superview != nil else { return }
        
        isInitialized = true

        setAccessibilityIdentifier()
        setUp()
        setUpLayout()
        setUpAppearance()
        updateContent()
    }
    
    open func setUp() { /* default empty implementation */ }
    open func setUpAppearance() { setNeedsLayout() }
    open func setUpLayout() { setNeedsLayout() }
    open func updateContent() { setNeedsLayout() }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 12, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        TraitCollectionReloadStack.push {
            self.setUpAppearance()
            self.updateContent()
        }
    }

    override open func layoutSubviews() {
        TraitCollectionReloadStack.executePendingUpdates()
        super.layoutSubviews()
    }
}

open class _ViewController: UIViewController, Customizable {
    override open var next: UIResponder? {
        // When `self` is being added to the parent controller, the default `next` implementation returns nil
        // unless the `self.view` is added as a subview to `parent.view`. But `self.viewDidLoad` is
        // called before the transition finishes so the subviews are created from `Components.default`.
        // To prevent responder chain from being cutoff during `ViewController` lifecycle we fallback to parent.
        super.next ?? parent
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
        setUpLayout()
        setUpAppearance()
        updateContent()
    }
    
    /**
     A function that will be called on first launch of the `View` it's a function that can be used
     for any initial setup work required by the `View` such as setting delegates or data sources
     
     `setUp()` is an important function within the ViewController lifecycle
     Its responsibility is to set the delegates and also call `synchronize()`
     this will make sure your local & remote data is in sync.
     
     - Important: If you override this method without calling `super.setUp()`, it's essential
     to make sure `synchronize()` is called.
     */
    open func setUp() { /* default empty implementation */ }
    open func setUpAppearance() { view.setNeedsLayout() }
    open func setUpLayout() { view.setNeedsLayout() }
    open func updateContent() { view.setNeedsLayout() }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 12, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        TraitCollectionReloadStack.push {
            self.setUpAppearance()
            self.updateContent()
        }
    }

    override open func viewWillLayoutSubviews() {
        TraitCollectionReloadStack.executePendingUpdates()
        super.viewWillLayoutSubviews()
    }
}

/// Closure stack, used to reverse order of appearance reloads on trait collection changes
private enum TraitCollectionReloadStack {
    private static var stack: [() -> Void] = []

    static func executePendingUpdates() {
        guard !stack.isEmpty else { return }
        let existingUpdates = stack
        stack.removeAll()
        existingUpdates.reversed().forEach { $0() }
    }

    static func push(_ closure: @escaping () -> Void) {
        stack.append(closure)
    }
}

/// Base class for overridable views StreamChatUI provides.
/// All conformers will have StreamChatUI appearance settings by default.
open class _TableViewCell: UITableViewCell, Customizable, AccessibilityView {
    // Flag for preventing multiple lifecycle methods calls.
    private var isInitialized: Bool = false

    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard !isInitialized, superview != nil else { return }

        isInitialized = true

        setAccessibilityIdentifier()
        setUp()
        setUpLayout()
        setUpAppearance()
        updateContent()
    }

    open func setUp() { /* default empty implementation */ }
    open func setUpAppearance() { /* default empty implementation */ }
    open func setUpLayout() { /* default empty implementation */ }
    open func updateContent() { /* default empty implementation */ }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 12, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        TraitCollectionReloadStack.push {
            self.setUpAppearance()
            self.updateContent()
        }
    }

    override open func layoutSubviews() {
        TraitCollectionReloadStack.executePendingUpdates()
        super.layoutSubviews()
    }
}
