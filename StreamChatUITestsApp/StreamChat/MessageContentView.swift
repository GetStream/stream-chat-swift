//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

/// Marks its cell with an accessibility value while the message has the jump highlight, so UI tests can see it.
/// This lives in the test app instead of the SDK so VoiceOver users never hear it.
final class MessageContentView: ChatMessageContentView {
    override var backgroundColor: UIColor? {
        didSet {
            let isHighlighted = backgroundColor == appearance.colorPalette.backgroundCoreHighlight
            messageCell?.accessibilityValue = isHighlighted ? "highlighted" : nil
        }
    }

    private var messageCell: UIView? {
        var view = superview
        while let current = view, !(current is ChatMessageCell) {
            view = current.superview
        }
        return view
    }
}
