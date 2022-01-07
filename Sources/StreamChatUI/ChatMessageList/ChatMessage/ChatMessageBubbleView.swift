//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays a bubble around a message.
open class ChatMessageBubbleView: _View, AppearanceProvider, SwiftUIRepresentable {
    /// A type describing the content of this view.
    public struct Content {
        /// The background color of the bubble.
        public let backgroundColor: UIColor
        /// The mask saying which corners should be rounded.
        public let roundedCorners: CACornerMask

        public init(backgroundColor: UIColor, roundedCorners: CACornerMask) {
            self.backgroundColor = backgroundColor
            self.roundedCorners = roundedCorners
        }
    }

    /// The content this view is rendered based on.
    open var content: Content? {
        didSet { updateContentIfNeeded() }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        layer.borderColor = appearance.colorPalette.border3.cgColor
        layer.cornerRadius = 18
        layer.borderWidth = 1
    }

    override open func updateContent() {
        super.updateContent()
        
        layer.maskedCorners = content?.roundedCorners ?? .all
        backgroundColor = content?.backgroundColor ?? .clear
    }
}
