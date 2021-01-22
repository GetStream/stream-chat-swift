//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension ChatMessageInteractiveAttachmentView {
    open class ActionButton: Button, UIConfigProvider {
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

            addTarget(self, action: #selector(didTouchUpInside), for: .touchUpInside)
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

        @objc open func didTouchUpInside() {
            content?.didTap()
        }
    }
}

// MARK: - Content

extension ChatMessageInteractiveAttachmentView.ActionButton {
    public struct Content {
        public let action: AttachmentAction
        public let didTap: () -> Void

        public init(action: AttachmentAction, didTap: @escaping () -> Void) {
            self.action = action
            self.didTap = didTap
        }
    }
}
