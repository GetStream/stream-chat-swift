//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public class Chat {
    private let channelController: ChatChannelController
        
    init(chatClient: ChatClient, channelId: ChannelId) {
        channelController = chatClient.channelController(for: channelId)
        channelController.delegate = self
        channelController.synchronize()
    }
    
    @MainActor public internal(set) var state = ChatState()
}

@available(iOS 13.0, *)
extension Chat: ChatChannelControllerDelegate {
    public func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {
        Task {
            await state.update(messages: channelController.messages)
        }
    }
}

@available(iOS 13.0, *)
@MainActor public class ChatState: ObservableObject {
    @Published public var messages = LazyCachedMapCollection<ChatMessage>()
    
    internal func update(messages: LazyCachedMapCollection<ChatMessage>) {
        self.messages = messages
    }
}

@available(iOS 13.0, *)
public extension ChatClient {
    func makeChat(for channelId: ChannelId) -> Chat {
        Chat(chatClient: self, channelId: channelId)
    }
}
