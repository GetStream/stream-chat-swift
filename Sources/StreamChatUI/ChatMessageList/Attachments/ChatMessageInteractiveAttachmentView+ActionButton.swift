//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension _ChatMessageInteractiveAttachmentView {
    open class ActionButton: _Button, UIConfigProvider {
        public var content: Content? {
            didSet { updateContentIfNeeded() }
        }

        // MARK: - Overrides

        public var defaultIntrinsicContentSize = CGSize(width: UIView.noIntrinsicMetric, height: 48)
        override open var intrinsicContentSize: CGSize {
            defaultIntrinsicContentSize
        }

        override public func defaultAppearance() {
            titleLabel?.font = uiConfig.font.body
        }

        override open func setUp() {
            super.setUp()

            addTarget(self, action: #selector(handleTouchUpInside), for: .touchUpInside)
        }

        override open func updateContent() {
            let titleColor = content?.action.style == .primary ?
                tintColor :
                uiConfig.colorPalette.subtitleText

            setTitle(content?.action.text, for: .normal)
            setTitleColor(titleColor, for: .normal)
            setTitleColor(
                titleColor.map(uiConfig.colorPalette.highlightedColorForColor),
                for: .highlighted
            )
            setTitleColor(
                titleColor.map(uiConfig.colorPalette.highlightedColorForColor),
                for: .selected
            )
        }
        
        override open func tintColorDidChange() {
            super.tintColorDidChange()

            updateContentIfNeeded()
        }

        // MARK: - Actions

        @objc open func handleTouchUpInside() {
            content?.handleTap()
        }
    }
}

// MARK: - Content

extension _ChatMessageInteractiveAttachmentView.ActionButton {
    public struct Content {
        public let action: AttachmentAction
        public let handleTap: () -> Void

        public init(action: AttachmentAction, didTap: @escaping () -> Void) {
            self.action = action
            handleTap = didTap
        }
    }
}
