//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that shows a number of unread messages on the Scroll-To-Latest-Message button in the Message List.
public typealias ChatMessageListUnreadCountView = _ChatMessageListUnreadCountView<NoExtraData>

/// A view that shows a number of unread messages on the Scroll-To-Latest-Message button in the Message List.
open class _ChatMessageListUnreadCountView<ExtraData: ExtraDataTypes>: _ChatChannelUnreadCountView<ExtraData> {
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        backgroundColor = tintColor
    }
}
