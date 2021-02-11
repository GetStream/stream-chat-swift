//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

// Just a protocol to formalize the methods required
public protocol Customizable {
    /// Main point of customization for the view functionality.
    /// Calling super implementation is required.
    func setUp()
    
    /// Main point of customization for appearance.
    /// Calling super is usually not needed.
    func setUpAppearance()
    
    /// Main point of customization for appearance.
    /// Calling super implementation is not necessary if you provide complete layout for all elements.
    func setUpLayout()
    
    /// Main point of updating views with the latest data.
    /// Calling super is recommended in most of the cases.
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
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }
        
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

        // Execute previous pending updates
        pendingUpdates?()

        // Add this view's updates to pending updates
        pendingUpdates = {
            (self as! Self).applyDefaultAppearance()
            self.setUpAppearance()
            self.updateContent()
        }

        // Make sure all pending updates are executed eventually
        DispatchQueue.main.async {
            pendingUpdates?()
            pendingUpdates = nil
        }
    }
}

/// Base class for overridable views StreamChatUI provides.
/// All conformers will have StreamChatUI appearance settings by default.
open class CollectionViewCell: UICollectionViewCell, AppearanceSetting, Customizable {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }
        
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

        // Execute previous pending updates
        pendingUpdates?()

        // Add this view's updates to pending updates
        pendingUpdates = {
            (self as! Self).applyDefaultAppearance()
            self.setUpAppearance()
            self.updateContent()
        }

        // Make sure all pending updates are executed eventually
        DispatchQueue.main.async {
            pendingUpdates?()
            pendingUpdates = nil
        }
    }
}

/// Base class for overridable views StreamChatUI provides.
/// All conformers will have StreamChatUI appearance settings by default.
open class Control: UIControl, AppearanceSetting, Customizable {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }
        
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

        // Execute previous pending updates
        pendingUpdates?()

        // Add this view's updates to pending updates
        pendingUpdates = {
            (self as! Self).applyDefaultAppearance()
            self.setUpAppearance()
            self.updateContent()
        }

        // Make sure all pending updates are executed eventually
        DispatchQueue.main.async {
            pendingUpdates?()
            pendingUpdates = nil
        }
    }
}

/// Base class for overridable views StreamChatUI provides.
/// All conformers will have StreamChatUI appearance settings by default.
open class Button: UIButton, AppearanceSetting, Customizable {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }
        
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

        // Execute previous pending updates
        pendingUpdates?()

        // Add this view's updates to pending updates
        pendingUpdates = {
            (self as! Self).applyDefaultAppearance()
            self.setUpAppearance()
            self.updateContent()
        }

        // Make sure all pending updates are executed eventually
        DispatchQueue.main.async {
            pendingUpdates?()
            pendingUpdates = nil
        }
    }
}

/// Base class for overridable views StreamChatUI provides.
/// All conformers will have StreamChatUI appearance settings by default.
open class NavigationBar: UINavigationBar, AppearanceSetting, Customizable {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }
        
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

        // Execute previous pending updates
        pendingUpdates?()

        // Add this view's updates to pending updates
        pendingUpdates = {
            (self as! Self).applyDefaultAppearance()
            self.setUpAppearance()
            self.updateContent()
        }

        // Make sure all pending updates are executed eventually
        DispatchQueue.main.async {
            pendingUpdates?()
            pendingUpdates = nil
        }
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

        // Execute previous pending updates
        pendingUpdates?()

        // Add this view's updates to pending updates
        pendingUpdates = {
            (self as! Self).applyDefaultAppearance()
            self.setUpAppearance()
            self.updateContent()
        }

        // Make sure all pending updates are executed eventually
        DispatchQueue.main.async {
            pendingUpdates?()
            pendingUpdates = nil
        }
    }
}

// This is just a temporary workaround! Proper solution in https://stream-io.atlassian.net/browse/CIS-658

private var pendingUpdates: (() -> Void)? {
    get {
        assert(Thread.isMainThread)
        return _pendingUpdates
    }
    set {
        assert(Thread.isMainThread)
        _pendingUpdates = newValue
    }
}

private var _pendingUpdates: (() -> Void)?
