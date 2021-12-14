//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A `NavigationRouter` instance responsible for presenting alerts.
open class AlertsRouter: NavigationRouter<UIViewController> {
    /// Shows an alert with confirmation for message deletion.
    ///
    /// - Parameters:
    ///     - confirmed: Completion closure with a `Bool` parameter indicating whether the deletion has been confirmed or not.
    ///
    open func showMessageDeletionConfirmationAlert(confirmed: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: L10n.Message.Actions.Delete.confirmationTitle,
            message: L10n.Message.Actions.Delete.confirmationMessage,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: L10n.Alert.Actions.cancel,
                style: .cancel,
                handler: { _ in confirmed(false) }
            )
        )
        alert.addAction(
            UIAlertAction(
                title: L10n.Alert.Actions.delete,
                style: .destructive,
                handler: { _ in confirmed(true) }
            )
        )

        rootViewController.present(alert, animated: true)
    }
}

extension UIAlertController {

    /// To show alert in viewController
    ///
    /// - Parameters:
    ///   - title: Title of alert like "My Alert"
    ///   - message: what the purpose of alert
    ///   - actions: get input from user
    ///   - preferredStyle: Constants indicating the type of alert to display
    /// - Returns: An object that displays an alert message to the user
    static public func showAlert(title: String?, message: String?, actions: [UIAlertAction], preferredStyle: UIAlertController.Style) -> UIAlertController {
        let controller = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        for action in actions {
            controller.addAction(action)
        }
        return controller
    }
}
