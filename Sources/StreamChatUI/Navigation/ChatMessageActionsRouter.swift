//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
    
    /// Shows an alert with confirmation for message flag.
    ///
    /// - Parameters:
    ///     - confirmed: Completion closure with a `Bool` parameter indicating whether the deletion has been confirmed or not.
    ///
    open func showMessageFlagConfirmationAlert(confirmed: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: L10n.Message.Actions.Flag.confirmationTitle,
            message: L10n.Message.Actions.Flag.confirmationMessage,
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
                title: L10n.Alert.Actions.flag,
                style: .destructive,
                handler: { _ in confirmed(true) }
            )
        )
        
        rootViewController.present(alert, animated: true)
    }
}
