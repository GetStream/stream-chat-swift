//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

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

/// Base class for overridable views StreamChatUI provides.
/// All conformers will have StreamChatUI appearance settings by default.
open class View: UIView, AppearanceSetting, Customizable {
    // Flag for preventing multiple lifecycle methods calls.
    private var isInitialized: Bool = false
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard !isInitialized, superview != nil else { return }
        
        isInitialized = true
        
        setUp()
        setUpLayout()
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        updateContent()
    }
    
    public func defaultAppearance() { /* default empty implementation */ }
    open func setUp() { /* default empty implementation */ }
    open func setUpAppearance() { /* default empty implementation */ }
    open func setUpLayout() { /* default empty implementation */ }
    open func updateContent() { /* default empty implementation */ }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 12, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        TraitCollectionReloadStack.push {
            (self as! Self).applyDefaultAppearance()
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
open class CollectionViewCell: UICollectionViewCell, AppearanceSetting, Customizable {
    // Flag for preventing multiple lifecycle methods calls.
    private var isInitialized: Bool = false
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard !isInitialized, superview != nil else { return }
        
        isInitialized = true
        
        setUp()
        setUpLayout()
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        updateContent()
    }
    
    public func defaultAppearance() { /* default empty implementation */ }
    open func setUp() { /* default empty implementation */ }
    open func setUpAppearance() { /* default empty implementation */ }
    open func setUpLayout() { /* default empty implementation */ }
    open func updateContent() { /* default empty implementation */ }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 12, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        TraitCollectionReloadStack.push {
            (self as! Self).applyDefaultAppearance()
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
open class Control: UIControl, AppearanceSetting, Customizable {
    // Flag for preventing multiple lifecycle methods calls.
    private var isInitialized: Bool = false
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard !isInitialized, superview != nil else { return }
        
        isInitialized = true
        
        setUp()
        setUpLayout()
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        updateContent()
    }
    
    public func defaultAppearance() { /* default empty implementation */ }
    open func setUp() { /* default empty implementation */ }
    open func setUpAppearance() { /* default empty implementation */ }
    open func setUpLayout() { /* default empty implementation */ }
    open func updateContent() { /* default empty implementation */ }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 12, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        TraitCollectionReloadStack.push {
            (self as! Self).applyDefaultAppearance()
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
open class Button: UIButton, AppearanceSetting, Customizable {
    // Flag for preventing multiple lifecycle methods calls.
    private var isInitialized: Bool = false
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard !isInitialized, superview != nil else { return }
        
        isInitialized = true
        
        setUp()
        setUpLayout()
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        updateContent()
    }
    
    public func defaultAppearance() { /* default empty implementation */ }
    open func setUp() { /* default empty implementation */ }
    open func setUpAppearance() { /* default empty implementation */ }
    open func setUpLayout() { /* default empty implementation */ }
    open func updateContent() { /* default empty implementation */ }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 12, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        TraitCollectionReloadStack.push {
            (self as! Self).applyDefaultAppearance()
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
open class NavigationBar: UINavigationBar, AppearanceSetting, Customizable {
    // Flag for preventing multiple lifecycle methods calls.
    private var isInitialized: Bool = false
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard !isInitialized, superview != nil else { return }
        
        isInitialized = true
        
        setUp()
        setUpLayout()
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        updateContent()
    }
    
    public func defaultAppearance() { /* default empty implementation */ }
    open func setUp() { /* default empty implementation */ }
    open func setUpAppearance() { /* default empty implementation */ }
    open func setUpLayout() { /* default empty implementation */ }
    open func updateContent() { /* default empty implementation */ }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 12, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        TraitCollectionReloadStack.push {
            (self as! Self).applyDefaultAppearance()
            self.setUpAppearance()
            self.updateContent()
        }
    }

    override open func layoutSubviews() {
        TraitCollectionReloadStack.executePendingUpdates()
        super.layoutSubviews()
    }
}

open class ViewController: UIViewController, AppearanceSetting, Customizable {
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
        setUpLayout()
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        updateContent()
    }
    
    public func defaultAppearance() { /* default empty implementation */ }
    open func setUp() { /* default empty implementation */ }
    open func setUpAppearance() { /* default empty implementation */ }
    open func setUpLayout() { /* default empty implementation */ }
    open func updateContent() { /* default empty implementation */ }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 12, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        TraitCollectionReloadStack.push {
            (self as! Self).applyDefaultAppearance()
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
