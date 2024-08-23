//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

    open func showPollAddCommentAlert(
        for poll: Poll,
        in messageId: MessageId,
        currentUserId: UserId,
        handler: @escaping (String) -> Void
    ) {
        let currentUserHasAnswer = poll.latestAnswers
            .compactMap(\.user?.id)
            .contains(currentUserId)

        let alert = UIAlertController(
            title: nil,
            message: currentUserHasAnswer ? L10n.Alert.Poll.updateComment : L10n.Alert.Poll.addComment,
            preferredStyle: .alert
        )
        alert.addTextField()
        alert.addAction(.init(title: L10n.Alert.Poll.send, style: .default, handler: { _ in
            guard let textFieldValue = alert.textFields?.first?.text else { return }
            guard !textFieldValue.isEmpty else { return }
            handler(textFieldValue)
        }))
        alert.addAction(.init(title: L10n.Alert.Actions.cancel, style: .cancel))
        rootViewController.present(alert, animated: true)
    }

    open func showPollEndVoteAlert(
        for poll: Poll,
        in messageId: MessageId,
        handler: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title: nil,
            message: L10n.Alert.Poll.endTitle,
            preferredStyle: .actionSheet
        )
        alert.addAction(.init(title: L10n.Alert.Poll.end, style: .destructive, handler: { _ in
            handler()
        }))
        alert.addAction(.init(title: L10n.Alert.Actions.cancel, style: .cancel))
        rootViewController.present(alert, animated: true)
    }
}
