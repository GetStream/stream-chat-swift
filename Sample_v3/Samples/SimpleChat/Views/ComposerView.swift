//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

class ComposerView: UIView {
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var textView: UITextView! {
        didSet {
            if #available(iOS 13.0, *) {
                textView.layer.borderColor = UIColor.opaqueSeparator.cgColor
            }

            textView.textContainerInset.right = 48
            textView.textContainerInset.left = 10
            textView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        }
    }
    
    var isKeyboardShown: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.5) {
                self.invalidateIntrinsicContentSize()
                self.superview?.setNeedsLayout()
                self.superview?.layoutIfNeeded()
            }
        }
    }

    var calculatedHeight: CGFloat {
        if isKeyboardShown {
            return textView.contentSize.height + 20
        } else {
            return textView.contentSize.height + 20 + (window?.safeAreaInsets.bottom ?? 0)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: super.intrinsicContentSize.width, height: calculatedHeight)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = false
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handle(keyboardShowNotification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handle(keyboardHideNotification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    @objc
    func handle(keyboardShowNotification notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let beginFrame = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect,
            let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else {
            return
        }
        
        if endFrame.size.height - beginFrame.height > intrinsicContentSize.height {
            isKeyboardShown = true
        }
    }
    
    @objc
    func handle(keyboardHideNotification notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let beginFrame = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect,
            let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else {
            return
        }
        
        if beginFrame.size.height - endFrame.height > intrinsicContentSize.height {
            isKeyboardShown = false
        }
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if object as AnyObject? === textView, keyPath == "contentSize" {
            invalidateIntrinsicContentSize()
        }
    }
}
