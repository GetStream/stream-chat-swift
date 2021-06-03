//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageListKeyboardObserver {
    public weak var containerView: UIView!
    public weak var collectionView: UICollectionView!
    public weak var composerBottomConstraint: NSLayoutConstraint?
    public weak var viewController: UIViewController?

    public init(
        containerView: UIView,
        collectionView: UICollectionView,
        composerBottomConstraint: NSLayoutConstraint?,
        viewController: UIViewController?
    ) {
        self.containerView = containerView
        self.collectionView = collectionView
        self.composerBottomConstraint = composerBottomConstraint
        self.viewController = viewController
    }
    
    public func register() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    public func unregister() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc
    private func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            viewController?.presentedViewController == nil,
            let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let keyboardAnimationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let keyboardAnimationCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let convertedKeyboardFrame = containerView.convert(keyboardFrame, from: UIScreen.main.coordinateSpace)
        let intersectedKeyboardHeight = containerView.frame.intersection(convertedKeyboardFrame).height

        composerBottomConstraint?.constant = -intersectedKeyboardHeight

        let indexPathNearestToKeyboard = collectionView.indexPathsForVisibleItems.sorted().first

        UIView.animate(
            withDuration: keyboardAnimationDuration,
            delay: 0.0,
            options: UIView.AnimationOptions(rawValue: keyboardAnimationCurve),
            animations: { [weak self] in
                self?.containerView.layoutIfNeeded()

                let isKeyboardShowing = intersectedKeyboardHeight > 0
                if let indexPathNearestToKeyboard = indexPathNearestToKeyboard, isKeyboardShowing {
                    self?.collectionView.scrollToItem(at: indexPathNearestToKeyboard, at: .bottom, animated: false)
                }
            }
        )
    }
}
