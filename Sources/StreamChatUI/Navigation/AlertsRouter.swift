//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A `NavigationRouter` instance responsible for presenting alerts.
open class AlertsRouter: NavigationRouter<UIViewController> {
    /// Shows an alert with confirmation for message deletion.
    ///
    /// - Parameters:
    ///   - confirmed: Completion closure with a `Bool` parameter indicating whether the deletion has been confirmed or not.
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
    ///   - confirmed: Completion closure with a `Bool` parameter indicating whether the deletion has been confirmed or not.
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

    /// Shows an alert to add a poll comment.
    ///
    /// - Parameters:
    ///   - poll: The poll to add a comment.
    ///   - messageId: The messageId which the poll belongs to.
    ///   - currentUserId: The user ID of the current logged in user.
    ///   - handler: The closure to handle the value that the user inputted.
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

    /// Shows an alert to add a suggestion of new poll option.
    ///
    /// - Parameters:
    ///   - poll: The poll to add a suggestion.
    ///   - messageId: The messageId which the poll belongs to.
    ///   - handler: The closure to handle the value that the user inputted.
    open func showPollAddSuggestionAlert(
        for poll: Poll,
        in messageId: MessageId,
        handler: @escaping (String) -> Void
    ) {
        let alert = UIAlertController(
            title: nil,
            message: L10n.Alert.Poll.suggestOption,
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

    /// Shows an alert to confirm that the user wants to end the poll.
    ///
    /// - Parameters:
    ///   - poll: The poll to be ended.
    ///   - messageId: The messageId which the poll belongs to.
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

    /// Shows an alert for the user to confirm it wants to discard his changes.
    open func showPollDiscardChangesAlert(handler: @escaping () -> Void) {
        let alert = UIAlertController(
            title: nil,
            message: L10n.Alert.Poll.discardChangesMessage,
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: L10n.Alert.Poll.discardChanges, style: .destructive, handler: { _ in
            handler()
        }))
        alert.addAction(UIAlertAction(title: L10n.Alert.Poll.keepEditing, style: .cancel, handler: nil))

        rootViewController.present(alert, animated: true)
    }

    /// Shows a generic error alert if it was not possible to create the poll from the backend.
    open func showPollCreationErrorAlert() {
        let alert = UIAlertController(
            title: L10n.Alert.Poll.genericErrorTitle,
            message: L10n.Alert.Poll.createErrorMessage,
            preferredStyle: .alert
        )
        alert.addAction(.init(title: L10n.Alert.Actions.ok, style: .default, handler: { _ in }))
        rootViewController.present(alert, animated: true)
    }
}
