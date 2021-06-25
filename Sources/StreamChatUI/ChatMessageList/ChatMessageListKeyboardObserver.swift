//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageListKeyboardObserver {
    public weak var containerView: UIView!
    public weak var composerBottomConstraint: NSLayoutConstraint?
    public weak var viewController: UIViewController?

    public init(
        containerView: UIView,
        composerBottomConstraint: NSLayoutConstraint?,
        viewController: UIViewController
    ) {
        self.containerView = containerView
        self.composerBottomConstraint = composerBottomConstraint
        self.viewController = viewController
    }
    
    open func register() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    open func unregister() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc
    open func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            viewController?.presentedViewController == nil,
            let frame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let keyboardFrameWithinContainer = containerView.convert(frame, from: nil)

        let overlap = containerView.frame.height - keyboardFrameWithinContainer.minY

        composerBottomConstraint?.constant = -overlap

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curve << 16)
        ) {
            self.containerView.layoutIfNeeded()
        }
    }
}
