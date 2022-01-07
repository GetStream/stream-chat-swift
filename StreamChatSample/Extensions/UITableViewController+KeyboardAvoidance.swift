//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

extension UITableViewController {
    func startAvoidingKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_onKeyboardFrameWillChangeNotificationReceived(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    func stopAvoidingKeyboard() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    func adjustContentInsetsIfNeeded() {
        guard presentedViewController == nil else {
            return
        }
        
        var contentInset = tableView.contentInset
        contentInset.bottom = topHeight
        contentInset.top = bottomHeight
        tableView.contentInset = contentInset
        tableView.scrollIndicatorInsets = contentInset
    }
    
    private var topHeight: CGFloat {
        if navigationController?.navigationBar.isTranslucent ?? false {
            var top = navigationController?.navigationBar.frame.height ?? 0.0
            top += UIApplication.shared.statusBarFrame.height
            return top
        }

        return 0.0
    }

    private var bottomHeight: CGFloat {
        guard let keyboardView = inputAccessoryView?.superview else {
            return 0
        }
        
        return view.frame.intersection(keyboardView.frame).height
    }
    
    private enum AssociatedKeys {
        static var keyboardHeight = "keyboardHeight"
    }

    private var keyboardHeight: CGFloat {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.keyboardHeight) as? CGFloat ?? 0
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.keyboardHeight,
                newValue,
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    @objc private func _onKeyboardFrameWillChangeNotificationReceived(_ notification: Notification) {
        guard
            presentedViewController == nil,
            let userInfo = notification.userInfo,
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else {
            return
        }

        let keyboardFrameInView = view.frame.intersection(keyboardFrame)
        let animationDuration: TimeInterval = (
            notification
                .userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber
        )?.doubleValue ?? 0
        let animationCurveRawNSN = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve = UIView.AnimationOptions(rawValue: animationCurveRaw)
        
        guard keyboardFrameInView.height != keyboardHeight else {
            return
        }

        let offset = keyboardFrameInView.height - keyboardHeight
        keyboardHeight = keyboardFrameInView.height
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
            // Update contentOffset with new keyboard size
            var contentOffset = self.tableView.contentOffset
            contentOffset.y -= offset
            self.tableView.contentOffset = contentOffset

            self.view.layoutIfNeeded()
        }, completion: { _ in
            UIView.performWithoutAnimation {
                self.view.layoutIfNeeded()
            }
        })
    }
}
