//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The component for handling keyboard events and adjust the composer.
open class ComposerKeyboardHandler: KeyboardHandler {
    public weak var composerParentVC: UIViewController?
    public weak var composerBottomConstraint: NSLayoutConstraint?
    public weak var messageListVC: ChatMessageListVC?

    public let originalBottomConstraintValue: CGFloat

    /// The component for handling keyboard events and adjust the composer.
    /// - Parameters:
    ///   - composerParentVC: The parent view controller of the composer.
    ///   - composerBottomConstraint: The bottom constraint of the composer.
    ///   - messageListVC: The message list view controller.
    public init(
        composerParentVC: UIViewController,
        composerBottomConstraint: NSLayoutConstraint?,
        messageListVC: ChatMessageListVC? = nil
    ) {
        self.messageListVC = messageListVC
        self.composerParentVC = composerParentVC
        self.composerBottomConstraint = composerBottomConstraint
        originalBottomConstraintValue = composerBottomConstraint?.constant ?? 0
    }

    open func start() {
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

    open func stop() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc open func keyboardWillChangeFrame(_ notification: Notification) {
        if composerParentVC?.presentedViewController is ChatMessagePopupVC {
            return
        }

        guard let userInfo = notification.userInfo,
              let frame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
              let composerParentView = composerParentVC?.view else {
            return
        }

        // When hiding, we reset the bottom constraint to the original value
        // When showing, we set the bottom constraint equal to the keyboard height + original value
        // The value is actually negative, so that the composer view goes up.

        let isHidingKeyboard = notification.name == UIResponder.keyboardWillHideNotification
        if isHidingKeyboard {
            composerBottomConstraint?.constant = originalBottomConstraintValue
        } else {
            let convertedKeyboardFrame = composerParentView.convert(frame, from: UIScreen.main.coordinateSpace)
            let intersectedKeyboardHeight = composerParentView.bounds.intersection(convertedKeyboardFrame).height

            let rootTabBar = composerParentView.window?.rootViewController?.tabBarController?.tabBar
            let shouldAddTabBarHeight = rootTabBar != nil && rootTabBar!.isTranslucent == false
            let rootTabBarHeight = shouldAddTabBarHeight ? rootTabBar!.frame.height : 0

            composerBottomConstraint?.constant = -(
                intersectedKeyboardHeight + originalBottomConstraintValue + rootTabBarHeight
            )
        }

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curve << 16)
        ) { [weak self] in
            composerParentView.layoutIfNeeded()
            self?.messageListVC?.listView.adjustContentInsetToPositionMessagesAtTheTop()
        }
    }
}
