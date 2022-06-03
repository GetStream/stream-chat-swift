//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
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
        cancelHandler: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        actions.forEach { alert.addAction($0) }
        alert.addAction(.init(title: "Cancel", style: .destructive, handler: { _ in
            cancelHandler?()
        }))

        present(alert, animated: true, completion: nil)
    }
}
