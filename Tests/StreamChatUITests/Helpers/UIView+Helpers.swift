//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIView {
    /// Simulate embedding in superview to execute view lifecycle methods.
    func executeLifecycleMethods() {
        UIView().addSubview(self)
    }
}

extension UIViewController {
    /// Trigger `viewDidLoad` to execute view lifecycle methods.
    func executeLifecycleMethods() {
        _ = view
    }
}

extension UIControl {
    /// Action methods are dispatched through the current `UIApplication` object,
    /// which finds an appropriate object to handle the message, following the responder chain if needed.
    /// This method allows to simulate events without having `UIApplication` object running.
    func simulateEvent(_ event: UIControl.Event) {
        for target in allTargets {
            let target = target as NSObjectProtocol
            for actionName in actions(forTarget: target, forControlEvent: event) ?? [] {
                let selector = Selector(actionName)
                target.perform(selector, with: self)
            }
        }
    }
}
