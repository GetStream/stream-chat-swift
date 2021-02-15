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

    /// It's common for appearance to depend on system settings. When system settings are changed,
    /// component needs to reset its appearance.
    func resetAppearance()
}

public extension Customizable {
    func resetAppearance() {
        setUpAppearance()
        updateContent()
    }
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
    open func setUp() { TraitCollectionWatcher.activate() }
    open func setUpAppearance() { /* default empty implementation */ }
    open func setUpLayout() { /* default empty implementation */ }
    open func updateContent() { /* default empty implementation */ }
    open func resetAppearance() {
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        updateContent()
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
    open func setUp() { TraitCollectionWatcher.activate() }
    open func setUpAppearance() { /* default empty implementation */ }
    open func setUpLayout() { /* default empty implementation */ }
    open func updateContent() { /* default empty implementation */ }
    open func resetAppearance() {
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        updateContent()
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
    open func setUp() { TraitCollectionWatcher.activate() }
    open func setUpAppearance() { /* default empty implementation */ }
    open func setUpLayout() { /* default empty implementation */ }
    open func updateContent() { /* default empty implementation */ }
    open func resetAppearance() {
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        updateContent()
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
    open func setUp() { TraitCollectionWatcher.activate() }
    open func setUpAppearance() { /* default empty implementation */ }
    open func setUpLayout() { /* default empty implementation */ }
    open func updateContent() { /* default empty implementation */ }
    open func resetAppearance() {
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        updateContent()
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
    open func setUp() { TraitCollectionWatcher.activate() }
    open func setUpAppearance() { /* default empty implementation */ }
    open func setUpLayout() { /* default empty implementation */ }
    open func updateContent() { /* default empty implementation */ }
    open func resetAppearance() {
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        updateContent()
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
    open func setUp() { TraitCollectionWatcher.activate() }
    open func setUpAppearance() { /* default empty implementation */ }
    open func setUpLayout() { /* default empty implementation */ }
    open func updateContent() { /* default empty implementation */ }
    open func resetAppearance() {
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        updateContent()
    }
}

/// Observes trait collection changes and calls `Customizable.resetAppearance` in child-first DFS way
/// on view & view controller hierarchies.
private enum TraitCollectionWatcher {
    private class TraitCollectionChangesObservingView: View {
        var onTraitChange: () -> Void = {}
        override func setUp() { /* do not call super to prevent loop */ } // swiftlint:disable:this overridden_super_call
        override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)

            guard #available(iOS 12, *) else { return }
            guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
            onTraitChange()
        }
    }

    private weak static var activeObservingView: TraitCollectionChangesObservingView?

    /// Integrate watcher in current view hierarchy if hasn't been yet.
    /// Can be called at any point.
    static func activate() {
        guard activeObservingView == nil else { return }

        // UIKit love to disable system calls for views that are not in hierarchy or hidden / zero sized / etc.
        // To play it safe, we put observing point outside of visible bounds
        let observingView = TraitCollectionChangesObservingView(frame: CGRect(x: -100, y: -100, width: 1, height: 1))
        observingView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        observingView.onTraitChange = {
            DispatchQueue.main.async {
                TraitCollectionWatcher.dfsAppearanceReset()
            }
        }

        UIApplication.shared.keyWindow?.addSubview(observingView)
        activeObservingView = observingView
    }

    private static func dfsAppearanceReset() {
        UIApplication.shared.windows.forEach {
            $0.dfsAppearanceReset()
        }
        UIApplication.shared.windows.forEach {
            $0.rootViewController?.dfsAppearanceReset()
        }
    }
}

private extension UIView {
    func dfsAppearanceReset() {
        subviews.forEach { $0.dfsAppearanceReset() }
        (self as? Customizable)?.resetAppearance()
    }
}

private extension UIViewController {
    func dfsAppearanceReset() {
        children.forEach { $0.dfsAppearanceReset() }
        presentedViewController?.dfsAppearanceReset()
        (self as? Customizable)?.resetAppearance()
    }
}
