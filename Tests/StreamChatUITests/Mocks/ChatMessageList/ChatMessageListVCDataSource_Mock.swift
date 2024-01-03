//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import UIKit

class ChatMessageListVCDataSource_Mock: ChatMessageListVCDataSource {
    var mockedIsFirstPageLoaded: Bool = true
    var isFirstPageLoaded: Bool {
        mockedIsFirstPageLoaded
    }
    
    var mockedIsLastPageLoaded: Bool = true
    var isLastPageLoaded: Bool {
        mockedIsLastPageLoaded
    }

    var mockedChannel: ChatChannel?
    func channel(for vc: ChatMessageListVC) -> ChatChannel? {
        mockedChannel
    }

    var messages: [StreamChat.ChatMessage] = []

    func numberOfMessages(in vc: StreamChatUI.ChatMessageListVC) -> Int {
        messages.count
    }

    func chatMessageListVC(_ vc: StreamChatUI.ChatMessageListVC, messageAt indexPath: IndexPath) -> StreamChat.ChatMessage? {
        messages[safe: indexPath.item]
    }

    func chatMessageListVC(_ vc: StreamChatUI.ChatMessageListVC, messageLayoutOptionsAt indexPath: IndexPath) -> StreamChatUI.ChatMessageLayoutOptions {
        .init()
    }
}
