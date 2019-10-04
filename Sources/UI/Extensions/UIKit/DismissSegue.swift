//
//  DismissSegue.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 02/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

final class DismissSegue: UIStoryboardSegue {
    
    override func perform() {
        guard let presentedViewController = source.presentingViewController?.presentedViewController else {
            return
        }
        
        if let topViewController = findTopViewController(in: presentedViewController),
            topViewController.viewIfLoaded?.window != nil {
            topViewController.view.endEditing(true)
        }
        
        presentedViewController.dismiss(animated: true)
    }
    
    private func findTopViewController(in viewController: UIViewController) -> UIViewController? {
        if let tabbarController = viewController as? UITabBarController,
            let selectedViewController = tabbarController.selectedViewController {
            return findTopViewController(in: selectedViewController)
        }
        
        if let navigationController = viewController as? UINavigationController {
            return navigationController.topViewController
        }
        
        return viewController
    }
}
