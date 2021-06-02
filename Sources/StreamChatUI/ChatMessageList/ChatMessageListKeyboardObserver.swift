//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageListKeyboardObserver {
    public weak var containerView: UIView!
    public weak var scrollView: UIScrollView!
    public weak var composerBottomConstraint: NSLayoutConstraint?
    public weak var viewController: UIViewController?

    public init(
        containerView: UIView,
        scrollView: UIScrollView,
        composerBottomConstraint: NSLayoutConstraint?,
        viewController: UIViewController?
    ) {
        self.containerView = containerView
        self.scrollView = scrollView
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
        // need to calculate delta in content when `contentSize` is smaller than `frame.size`
        let contentDelta = max(
            // 8 is just some padding constant to make it look better
            scrollView.frame.height - scrollView.contentSize.height + scrollView.contentOffset.y - 8,
            // 0 is for the case when `contentSize` if larger than `frame.size`
            0
        )
        
        let newContentOffset = CGPoint(
            x: 0,
            y: max(
                scrollView.contentOffset.y + keyboardDelta - contentDelta,
                // case when keyboard is activated but not shown, probably only on simulator
                -scrollView.contentInset.top
            )
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
