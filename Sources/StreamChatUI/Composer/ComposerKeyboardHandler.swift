//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A component responsible to handle keyboard events and act on them.
public protocol KeyboardHandler {
    /// Start handling events.
    func start()
    /// Stop handling events.
    func stop()
}

/// The component for handling keyboard events and adjust the composer.
open class ComposerKeyboardHandler: KeyboardHandler {
    public weak var composerParentVC: UIViewController?
    public weak var composerBottomConstraint: NSLayoutConstraint?

    /// The component for handling keyboard events and adjust the composer.
    /// - Parameters:
    ///   - composerParentVC: The parent view controller of the composer.
    ///   - composerBottomConstraint: The bottom constraint of the composer.
    public init(
        composerParentVC: UIViewController,
        composerBottomConstraint: NSLayoutConstraint?
    ) {
        self.composerParentVC = composerParentVC
        self.composerBottomConstraint = composerBottomConstraint
    }

    open func start() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    open func stop() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc open func keyboardWillChangeFrame(_ notification: Notification) {
        guard composerParentVC?.presentedViewController == nil,
              let userInfo = notification.userInfo,
              let frame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
              let composerParentView = composerParentVC?.view else {
            return
        }

        let convertedKeyboardFrame = composerParentView.convert(frame, from: UIScreen.main.coordinateSpace)

        let intersectedKeyboardHeight = composerParentView.frame.intersection(convertedKeyboardFrame).height

        composerBottomConstraint?.constant = -intersectedKeyboardHeight

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curve << 16)
        ) {
            composerParentView.layoutIfNeeded()
        }
    }
}
