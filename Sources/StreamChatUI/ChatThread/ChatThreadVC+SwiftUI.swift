//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOSApplicationExtension, unavailable)
extension ChatThreadVC: SwiftUIRepresentable {
    @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
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
