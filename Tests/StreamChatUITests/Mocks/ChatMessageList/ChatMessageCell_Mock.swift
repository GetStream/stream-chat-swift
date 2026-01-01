//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import UIKit

class ChatMessageCell_Mock: ChatMessageCell {
    var mockedMessage: ChatMessage?

    override var messageContentView: ChatMessageContentView? {
        let view = ChatMessageContentView()
        view.content = mockedMessage
        return view
    }
}
