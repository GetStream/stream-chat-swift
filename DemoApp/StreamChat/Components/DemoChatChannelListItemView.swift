//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChatUI

final class DemoChatChannelListItemView: ChatChannelListItemView {
    override func updateContent() {
        super.updateContent()

        if AppConfig.shared.demoAppConfig.isChannelPinningEnabled && content?.channel.isPinned == true {
            backgroundColor = appearance.colorPalette.pinnedMessageBackground
        }
    }
}
