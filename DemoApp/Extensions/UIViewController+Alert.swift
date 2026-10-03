//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatLogsUI
import UIKit

extension UIViewController {
    func presentAlert(
        title: String?,
        message: String? = nil,
        okHandler: (() -> Void)? = nil,
        cancelHandler: (() -> Void)? = nil
    ) {
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

    func presentAlert(
        title: String?,
        message: String? = nil,
        actions: [UIAlertAction],
        cancelHandler: (() -> Void)? = nil,
        preferredStyle: UIAlertController.Style = .alert,
        sourceView: UIView? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: preferredStyle
        )
        alert.popoverPresentationController?.sourceView = sourceView

        actions.forEach { alert.addAction($0) }
        alert.addAction(.init(title: "Cancel", style: .destructive, handler: { _ in
            cancelHandler?()
        }))

        present(alert, animated: true, completion: nil)
    }

    func presentUserOptionsAlert(
        onLogout: (() -> Void)?,
        onDisconnect: (() -> Void)?,
        client: ChatClient
    ) {
        var actions: [UIAlertAction] = [
            .init(title: "Show Profile", style: .default, handler: { [weak self] _ in
                let viewController = UserProfileViewController(
                    currentUserController: client.currentUserController()
                )
                self?.navigationController?.pushViewController(viewController, animated: true)
            })
        ]
        if #available(iOS 16.0, *) {
            actions.append(.init(title: "Show Logs", style: .default, handler: { _ in
                LogViewer.present()
            }))
        }
        actions += [
            .init(title: "Logout", style: .destructive, handler: { _ in
                onLogout?()
            }),
            .init(title: "Disconnect", style: .destructive, handler: { _ in
                onDisconnect?()
            })
        ]
        presentAlert(title: nil, actions: actions)
    }
}
