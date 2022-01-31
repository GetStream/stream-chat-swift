//
//  KeyboardService.swift
//  StreamChat
//
//  Created by Parth Kshatriya on 31/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

open class KeyboardService: NSObject {
    public static var shared = KeyboardService()
    public var measuredSize = 0.0

    public class func keyboardSize() -> CGFloat {
        return UserDefaults.standard.value(forKey: "keyboardHeight") as? CGFloat ?? UIScreen.main.bounds.height * 0.33
    }

    private func observeKeyboardNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(self.keyboardChange), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

   public func observeKeyboard(_ view: UIView) {
        if let keyboardHeight = UserDefaults.standard.value(forKey: "keyboardHeight") as? CGFloat {
            measuredSize = keyboardHeight
        } else {
            let field = UITextField()
            view.addSubview(field)
            field.becomeFirstResponder()
        }
    }

    @objc private func keyboardChange(_ notification: Notification) {
        guard measuredSize == 0.0, let info = notification.userInfo,
              let value = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else { return }
        measuredSize = value.cgRectValue.height
        UserDefaults.standard.set(measuredSize, forKey: "keyboardHeight")
        UserDefaults.standard.synchronize()
    }

    override init() {
        super.init()
        observeKeyboardNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
