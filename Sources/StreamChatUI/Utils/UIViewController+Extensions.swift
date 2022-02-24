//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIViewController {
    func addChildViewController(_ child: UIViewController, targetView superview: UIView) {
        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
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

extension UIViewController {
    func presentAlert(title: String?,
                      message: String? = nil,
                      okHandler: (() -> Void)? = nil,
                      cancelHandler: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(.init(title: "OK", style: .default, handler: { _ in
            okHandler?()
        }))
        if let cancelHandler = cancelHandler {
            alert.addAction(.init(title: "Cancel", style: .destructive, handler: { _ in
                cancelHandler()
            }))
        }
        present(alert, animated: true, completion: nil)
    }

    func presentAlert(
        title: String?,
        message: String? = nil,
        textFieldPlaceholder: String? = nil,
        okHandler: @escaping ((String?) -> Void),
        cancelHandler: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = textFieldPlaceholder
        }
        alert.addAction(.init(title: "OK", style: .default, handler: { _ in
            okHandler(alert.textFields?.first?.text)
        }))
        alert.addAction(.init(title: "Cancel", style: .destructive, handler: { _ in
            cancelHandler?()
        }))
        present(alert, animated: true, completion: nil)
    }

    func presentAlert(title: String?,
                      message: String? = nil,
                      actions: [UIAlertAction]) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        actions.forEach { alert.addAction($0) }
        present(alert, animated: true, completion: nil)
    }
}

public class pushTransition: CATransition {}

extension UIViewController {
    public func pushWithAnimation(controller: UIViewController) {
        for subLayer in self.view.layer.sublayers ?? [] {
            if subLayer.isKind(of: pushTransition.self) {
                subLayer.removeFromSuperlayer()
            }
        }
        let transition = pushTransition()
        transition.duration = TimeInterval(UINavigationController.hideShowBarDuration)
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.moveIn
        transition.subtype = .fromRight
        navigationController?.transitioningDelegate
        self.navigationController?.view.layer.add(transition, forKey: nil)
        self.navigationController?.pushViewController(controller, animated: false)
    }
    public func popWithAnimation() {
        for subLayer in self.view.layer.sublayers ?? [] {
            if subLayer.isKind(of: pushTransition.self) {
                subLayer.removeFromSuperlayer()
            }
        }
        let transition = pushTransition()
        transition.duration = TimeInterval(UINavigationController.hideShowBarDuration)
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.reveal
        transition.subtype = .fromLeft
        self.navigationController?.view.layer.add(transition, forKey: nil)
        self.navigationController?.popViewController(animated: false)
    }
}
