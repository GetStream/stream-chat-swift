//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// A root class for all routes in the SDK.
///
/// Router objects are used to handle navigation between view controllers.
///
/// - Important: ⚠️ The lifetime of a router must be similar to the lifetime of its `rootViewController`. Only the
/// root view controller is allowed to hold a strong reference to its router object.
///
open class NavigationRouter<Controller: UIViewController>: UIResponder {
    /// The root `UIViewController` object of this router.
    public unowned var rootViewController: Controller

    /// A convenience method to get the navigation controller of the root view controller.
    public var rootNavigationController: UINavigationController? {
        rootViewController.navigationController
    }

    // `NavigationRouter` has to be part of the responder chain because we need access to the current
    // `Components` and `Appearance` objects.
    override open var next: UIResponder? {
        rootViewController.next
    }

    /// Creates a new instance of `NavigationRouter`.
    ///
    /// - Parameter rootViewController: The view controller used as the root VC.
    ///
    public required init(rootViewController: Controller) {
        self.rootViewController = rootViewController
    }
}
