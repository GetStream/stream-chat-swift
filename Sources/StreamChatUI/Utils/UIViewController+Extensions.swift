//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIViewController {
    func addChildViewController(_ child: UIViewController, targetView superview: UIView) {
        addChild(child)
        superview.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    /// Adds `child` as a child view controller to `self` and as an arranged subview of `ContainerView`.
    func addChildViewController(_ child: UIViewController, targetView superview: ContainerStackView) {
        addChild(child)
        superview.addArrangedSubview(child.view)
        child.didMove(toParent: self)
    }
    
    func addChildViewController(_ child: UIViewController, embedIn superview: UIView) {
        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        superview.embed(child.view)
        child.didMove(toParent: self)
    }

    func removeFromParentViewController() {
        guard parent != nil else { return }

        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }

    var isUIHostingController: Bool {
        String(describing: self).contains("UIHostingController")
    }

    /// Helper method to correctly setup navigation of parent.
    /// Used when view is wrapped using `UIHostingController` and used in SwiftUI
    /// so all properties of `navigationItem` are propagated correctly.
    @available(iOS 13.0, *)
    func setupParentNavigation(parent: UIViewController) {
        let parentNavItem = parent.navigationItem

        if parentNavItem.backBarButtonItem == nil {
            parentNavItem.backBarButtonItem = navigationItem.backBarButtonItem
        }

        if #available(iOS 14.0, *) {
            if parent.navigationItem.backButtonDisplayMode == .default {
                parent.navigationItem.backButtonDisplayMode = navigationItem.backButtonDisplayMode
            }
        }

        if parentNavItem.backButtonTitle == nil {
            parentNavItem.backButtonTitle = navigationItem.backButtonTitle
        }

        if parentNavItem.compactAppearance == nil {
            parentNavItem.compactAppearance = navigationItem.compactAppearance
        }

        if parentNavItem.hidesSearchBarWhenScrolling {
            parent.navigationItem.hidesSearchBarWhenScrolling = navigationItem.hidesSearchBarWhenScrolling
        }

        if parent.navigationItem.largeTitleDisplayMode == .automatic {
            parentNavItem.largeTitleDisplayMode = navigationItem.largeTitleDisplayMode
        }

        if parent.navigationItem.hidesBackButton == false {
            parent.navigationItem.hidesBackButton = navigationItem.hidesBackButton
        }

        if parentNavItem.leftBarButtonItems == nil || parentNavItem.leftBarButtonItems?.isEmpty == true {
            parentNavItem.leftBarButtonItems = navigationItem.leftBarButtonItems
        }

        if parent.navigationItem.leftItemsSupplementBackButton == false {
            parent.navigationItem.leftItemsSupplementBackButton = navigationItem.leftItemsSupplementBackButton
        }

        if parentNavItem.prompt == nil {
            parentNavItem.prompt = navigationItem.prompt
        }

        if parentNavItem.rightBarButtonItems == nil || parentNavItem.rightBarButtonItems?.isEmpty == true {
            parentNavItem.rightBarButtonItems = navigationItem.rightBarButtonItems
        }

        if parentNavItem.scrollEdgeAppearance == nil {
            parentNavItem.scrollEdgeAppearance = navigationItem.scrollEdgeAppearance
        }

        if parentNavItem.searchController == nil {
            parentNavItem.searchController = navigationItem.searchController
        }

        if parentNavItem.standardAppearance == nil {
            parentNavItem.standardAppearance = navigationItem.standardAppearance
        }

        if parentNavItem.title == nil {
            parentNavItem.title = title
        }

        if parentNavItem.titleView == nil {
            parentNavItem.titleView = navigationItem.titleView
        }
    }
}
