// LINK: https://getstream.io/chat/docs/ios-swift/ios_styles/?preview=1&language=swift#injecting-custom-subclass

import StreamChatUI
import UIKit

private class DuckBubbleView: ChatMessageContentView {}

func snippets_ux_customizing_views_injecting_custom_subclass_3() {
    // > import UIKit
    // > import StreamChatUI

    UIConfig.default.messageList.messageContentView = DuckBubbleView.self
}
