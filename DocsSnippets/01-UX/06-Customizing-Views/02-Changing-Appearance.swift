// LINK: https://getstream.io/chat/docs/ios-swift/ios_styles/?preview=1&language=swift#changing-appearance

import StreamChatUI
import UIKit

func snippets_ux_customizing_views_changing_appearance() {
    // > import UIKit
    // > import StreamChatUI

    UIConfig.default.channelList.itemView.defaultAppearance.addRule {
        $0.backgroundColor = UIColor.yellow.withAlphaComponent(0.2)
        $0.titleLabel.textColor = .darkGray
    }
}
