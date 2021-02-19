//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageActionsRouter = _ChatMessageActionsRouter<NoExtraData>

internal class _ChatMessageActionsRouter<ExtraData: ExtraDataTypes>: ChatRouter<_ChatMessageActionsVC<ExtraData>> {
    internal func showMessageDeletionConfirmationAlert(confirmed: @escaping (Bool) -> Void) {
        guard let root = rootViewController else {
            log.error("Can't preset the message delete confirmation alert because the root VC is `nil`.")
            return
        }

        let alert = UIAlertController(
            title: L10n.Message.Actions.Delete.confirmationTitle,
            message: L10n.Message.Actions.Delete.confirmationMessage,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(
            title: L10n.Alert.Actions.cancel,
            style: .cancel,
            handler: { _ in confirmed(false) }
        ))
        alert.addAction(UIAlertAction(
            title: L10n.Alert.Actions.delete,
            style: .destructive,
            handler: { _ in confirmed(true) }
        ))

        root.present(alert, animated: true)
    }
}
