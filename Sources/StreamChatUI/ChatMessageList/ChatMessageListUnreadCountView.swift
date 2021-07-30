//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that shows a number of unread messages on the Scroll-To-Latest-Message button in the Message List.
open class ChatMessageListUnreadCountView: ChatChannelUnreadCountView {
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        backgroundColor = tintColor
    }
}
