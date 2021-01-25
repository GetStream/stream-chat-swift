//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

extension _ChatMessageActionsView {
    open class ActionButton: Button, UIConfigProvider {
        public var actionItem: ChatMessageActionItem? {
            didSet { updateContentIfNeeded() }
        }

        // MARK: Overrides

        override public func defaultAppearance() {
            backgroundColor = uiConfig.colorPalette.generalBackground
            titleLabel?.font = uiConfig.font.body
            contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
            contentHorizontalAlignment = .left
        }

        override open func setUp() {
            super.setUp()
            
            addTarget(self, action: #selector(touchUpInsideHandler(_:)), for: .touchUpInside)
        }

        override open func tintColorDidChange() {
            super.tintColorDidChange()
            
            updateContentIfNeeded()
        }
        
        override open func updateContent() {
            let imageTintСolor: UIColor
            let titleTextColor: UIColor

            if actionItem?.isDestructive == true {
                imageTintСolor = uiConfig.colorPalette.messageActionErrorTint
                titleTextColor = imageTintСolor
            } else {
                imageTintСolor = actionItem?.isPrimary == true ? tintColor : uiConfig.colorPalette.messageActionDefaultIconTint
                titleTextColor = uiConfig.colorPalette.messageActionDefaultText
            }

            setImage(actionItem?.icon.tinted(with: imageTintСolor), for: .normal)
            setTitle(actionItem?.title, for: .normal)
            setTitleColor(titleTextColor, for: .normal)
        }

        // MARK: Actions
        
        @objc open func touchUpInsideHandler(_ sender: Any) {
            actionItem?.action()
        }
    }
}
