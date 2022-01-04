//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// Text View that ignores all user interactions except touches on links
class OnlyLinkTappableTextView: UITextView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let range = characterRange(at: point),
           !range.isEmpty,
           let position = closestPosition(to: point, within: range),
           let styles = textStyling(at: position, in: .forward),
           styles[.link] != nil {
            return super.hitTest(point, with: event)
        } else {
            return nil
        }
    }
}
