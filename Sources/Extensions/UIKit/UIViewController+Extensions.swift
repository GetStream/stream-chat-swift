//
//  UIViewController+Extensions.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 02/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIViewController {
    public var isVisible: Bool {
        return isViewLoaded && view.window != nil
    }

    /// Hides the back button title from the navigation bar.
    public func hideBackButtonTitle() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
}
