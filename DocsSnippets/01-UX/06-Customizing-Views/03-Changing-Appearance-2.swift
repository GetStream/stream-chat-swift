// LINK: https://getstream.io/chat/docs/ios-swift/ios_styles/?preview=1&language=swift#changing-appearance

import StreamChatUI
import UIKit

func snippets_ux_customizing_views_changing_appearance_2() {
    // > import UIKit
    // > import StreamChatUI

    UIConfig.default.channelList.channelListItemSubviews.unreadCountView.defaultAppearance.addRule {
        $0.backgroundColor = .darkGray
    }
}
