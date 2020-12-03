//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

extension MessageActionsView {
    open class ActionButton: Button {
        public var actionItem: ChatMessageActionItem? {
            didSet { updateContentIfNeeded() }
        }

        // MARK: Overrides

        override open func defaultAppearance() {
            backgroundColor = .chatBackground
            contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
            contentHorizontalAlignment = .left
        }

        override open func setUp() {
            super.setUp()
            
            addTarget(self, action: #selector(touchUpInsideHandler(_:)), for: .touchUpInside)
        }
        
        override open func updateContent() {
            setImage(actionItem?.icon, for: .normal)
            tintColor = actionItem?.isDestructive == true ? .systemRed : .darkGray
            imageView?.tintColor = tintColor

            let titleColor: UIColor = actionItem?.isDestructive == true ? .systemRed : .black
            setTitle(actionItem?.title, for: .normal)
            titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline).bold()
            setTitleColor(titleColor, for: .normal)
        }

        // MARK: Actions
        
        @objc open func touchUpInsideHandler(_ sender: Any) {
            actionItem?.action()
        }
    }
}
