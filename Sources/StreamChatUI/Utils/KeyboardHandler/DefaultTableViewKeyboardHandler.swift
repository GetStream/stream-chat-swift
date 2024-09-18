//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// The component for handling keyboard events in a table view.
open class DefaultTableViewKeyboardHandler: KeyboardHandler {
    public weak var tableView: UITableView?

    public init(tableView: UITableView?) {
        self.tableView = tableView
    }

    public func start() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }

    // swiftlint:disable notification_center_detachment

    public func stop() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc open func keyboardWillChangeFrame(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curve << 16)
        ) { [weak self] in
            let insets = UIEdgeInsets(top: 0, left: 0, bottom: frame.height, right: 0)
            self?.tableView?.contentInset = insets
            self?.tableView?.scrollIndicatorInsets = insets
        }
    }
}
