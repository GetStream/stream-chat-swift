//
//  ViewController.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 03/09/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

/// A general view controller.
open class ViewController: UIViewController {
    
    /// Checks if the view controller’s view is visible for updates or not.
    open var isVisible: Bool {
        return viewIfLoaded?.window != nil
    }
    
    // MARK: - Banners
    
    /// Shows a banner with a given title.
    ///
    /// - Parameters:
    ///   - title: a banner title.
    ///   - delay: a delay before it will be hidden (1...5 sec).
    ///   - backgroundColor: a background color.
    ///   - borderColor: a border color.
    open func showBanner(_ title: String,
                         delay: TimeInterval = 3,
                         backgroundColor: UIColor = .white,
                         borderColor: UIColor? = nil) {
        Banners.shared.show(title, delay: delay, backgroundColor: backgroundColor, borderColor: borderColor)
    }
    
    /// Shows error message.
    ///
    /// - Parameter errorMessage: an error message.
    open func show(errorMessage: String) {
        Banners.shared.show(errorMessage: errorMessage)
    }
    
    /// Shows error.
    ///
    /// - Parameter error: an error.
    open func show(error: Error) {
        Banners.shared.show(error: error)
    }
    
    open func showAlert(title: String?,
                        message: String?,
                        actions: [UIAlertAction] = [.init(title: "Ok", style: .default, handler: nil)]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach(alert.addAction)
        present(alert, animated: true)
    }
}
