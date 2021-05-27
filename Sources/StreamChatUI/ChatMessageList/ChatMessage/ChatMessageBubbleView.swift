//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays a bubble around a message.
public typealias ChatMessageBubbleView = _ChatMessageBubbleView<NoExtraData>

/// A view that displays a bubble around a message.
open class _ChatMessageBubbleView<ExtraData: ExtraDataTypes>: _View, AppearanceProvider, SwiftUIRepresentable {
    /// A type describing the content of this view.
    public struct Content {
        /// The message to show the bubble for.
        public let message: _ChatMessage<ExtraData>
        /// The layout options the message content view is shown with.
        public let layoutOptions: ChatMessageLayoutOptions

        public init(message: _ChatMessage<ExtraData>, layoutOptions: ChatMessageLayoutOptions) {
            self.message = message
            self.layoutOptions = layoutOptions
        }
    }

    /// The content this view is rendered based on.
    open var content: Content? {
        didSet { updateContentIfNeeded() }
    }

    /// Returns a corner mask based on the `content`. The value is applied in `updateContent`.
    open var bubbleRoundedCorners: CACornerMask {
        guard let layout = content?.layoutOptions else { return .all }

        if layout.contains(.continuousBubble) {
            return .all
        } else if layout.contains(.flipped) {
            return CACornerMask.all.subtracting(.layerMaxXMaxYCorner)
        } else {
            return CACornerMask.all.subtracting(.layerMinXMaxYCorner)
        }
    }

    /// Returns a background color based on the `content`. The value is applied in `updateContent`.
    open var bubbleBackgroundColor: UIColor {
        guard let message = content?.message else { return .clear }

        if message.isSentByCurrentUser {
            if message.type == .ephemeral {
                return appearance.colorPalette.background8
            } else {
                return appearance.colorPalette.background6
            }
        } else {
            return appearance.colorPalette.background8
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        layer.borderColor = appearance.colorPalette.border3.cgColor
        layer.cornerRadius = 18
        layer.borderWidth = 1
    }

    override open func updateContent() {
        super.updateContent()

        layer.maskedCorners = bubbleRoundedCorners
        backgroundColor = bubbleBackgroundColor
    }
}
