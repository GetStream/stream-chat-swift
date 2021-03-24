//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

final class KeyboardFrameObserver {
    weak var containerView: UIView!
    weak var scrollView: UIScrollView!
    weak var composerBottomConstraint: NSLayoutConstraint?
    
    init(containerView: UIView, scrollView: UIScrollView, composerBottomConstraint: NSLayoutConstraint?) {
        self.containerView = containerView
        self.scrollView = scrollView
        self.composerBottomConstraint = composerBottomConstraint
    }
    
    public func register() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    @objc
    private func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let frame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let oldFrame = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let localFrame = containerView.convert(frame, from: nil)
        let localOldFrame = containerView.convert(oldFrame, from: nil)

        // message composer follows keyboard
        composerBottomConstraint?.constant = -(containerView.bounds.height - localFrame.minY)

        // calculate new contentOffset for message list, so bottom message still visible when keyboard appears
        var keyboardTop = localFrame.minY
        if keyboardTop == containerView.bounds.height {
            keyboardTop -= containerView.safeAreaInsets.bottom
        }

        var oldKeyboardTop = localOldFrame.minY
        if oldKeyboardTop == containerView.bounds.height {
            oldKeyboardTop -= containerView.safeAreaInsets.bottom
        }

        let keyboardDelta = oldKeyboardTop - keyboardTop
        let newContentOffset = CGPoint(
            x: 0,
            y: scrollView.contentOffset.y + keyboardDelta
        )

        // changing contentOffset will cancel any scrolling in collectionView, bad UX
        let needUpdateContentOffset = !scrollView.isDecelerating && !scrollView.isDragging
        
        UIView.animate(
            withDuration: duration,
            delay: 0.0,
            options: UIView.AnimationOptions(rawValue: curve),
            animations: { [weak self] in
                self?.containerView.layoutIfNeeded()
                if needUpdateContentOffset {
                    self?.scrollView.contentOffset = newContentOffset
                }
            }
        )
    }
}
