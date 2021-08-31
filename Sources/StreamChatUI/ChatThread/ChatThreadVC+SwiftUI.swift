//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOSApplicationExtension, unavailable)
extension ChatThreadVC: SwiftUIRepresentable {
    public var content: (
        channelController: ChatChannelController,
        messageController: ChatMessageController
    ) {
        get {
            (channelController, messageController)
        }
        set {
            channelController = newValue.channelController
            messageController = newValue.messageController
        }
    }
}
