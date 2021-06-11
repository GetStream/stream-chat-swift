//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension _ChatMessageInteractiveAttachmentView {
    open class ActionButton: _Button, AppearanceProvider {
        public var content: AttachmentAction? {
            didSet { updateContentIfNeeded() }
        }

        public var didTap: (() -> Void)?

        // MARK: - Overrides

        public var defaultIntrinsicContentSize = CGSize(width: UIView.noIntrinsicMetric, height: 48)
        override open var intrinsicContentSize: CGSize {
            defaultIntrinsicContentSize
        }

        override open func setUpAppearance() {
            super.setUpAppearance()
            titleLabel?.font = appearance.fonts.body
        }

        override open func setUp() {
            super.setUp()

            addTarget(self, action: #selector(handleTouchUpInside), for: .touchUpInside)
        }

        override open func updateContent() {
            let titleColor = content?.style == .primary ?
                tintColor :
                appearance.colorPalette.subtitleText

            setTitle(content?.text, for: .normal)
            setTitleColor(titleColor, for: .normal)
            setTitleColor(
                titleColor.map(appearance.colorPalette.highlightedColorForColor),
                for: .highlighted
            )
            setTitleColor(
                titleColor.map(appearance.colorPalette.highlightedColorForColor),
                for: .selected
            )
        }
        
        override open func tintColorDidChange() {
            super.tintColorDidChange()

            updateContentIfNeeded()
        }

        // MARK: - Actions

        @objc open func handleTouchUpInside() {
            didTap?()
        }
    }
}

// MARK: - Content

extension _ChatMessageInteractiveAttachmentView.ActionButton {
    public struct Content {
        public let action: AttachmentAction
        public let didTap: () -> Void

        public init(action: AttachmentAction, didTap: @escaping () -> Void) {
            self.action = action
            self.didTap = didTap
        }
    }
}
