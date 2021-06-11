//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension _ChatMessageInteractiveAttachmentView {
    internal class ActionButton: _Button, UIConfigProvider {
        internal var content: Content? {
            didSet { updateContentIfNeeded() }
        }

        // MARK: - Overrides

        internal var defaultIntrinsicContentSize = CGSize(width: UIView.noIntrinsicMetric, height: 48)
        override internal var intrinsicContentSize: CGSize {
            defaultIntrinsicContentSize
        }

        override internal func defaultAppearance() {
            titleLabel?.font = uiConfig.fonts.body
        }

        override internal func setUp() {
            super.setUp()

            addTarget(self, action: #selector(handleTouchUpInside), for: .touchUpInside)
        }

        override internal func updateContent() {
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
        
        override internal func tintColorDidChange() {
            super.tintColorDidChange()

            updateContentIfNeeded()
        }

        // MARK: - Actions

        @objc internal func handleTouchUpInside() {
            content?.handleTap()
        }
    }
}

// MARK: - Content

extension _ChatMessageInteractiveAttachmentView.ActionButton {
    internal struct Content {
        internal let action: AttachmentAction
        internal let handleTap: () -> Void

        internal init(action: AttachmentAction, didTap: @escaping () -> Void) {
            self.action = action
            handleTap = didTap
        }
    }
}
