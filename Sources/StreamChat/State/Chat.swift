//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public class Chat {
    private let channelController: ChatChannelController
    private let eventsController: EventsController
    
    private var pendingMessageContinuations = [MessageId: CheckedContinuation<MessageId, Error>]()
    private var pendingPaginationContinuations = [CheckedContinuation<Void, Error>]()
        
    init(chatClient: ChatClient, channelId: ChannelId) {
        channelController = chatClient.channelController(for: channelId)
        eventsController = chatClient.eventsController()
        eventsController.delegate = self
        channelController.delegate = self
        channelController.synchronize()
    }
    
    @MainActor public internal(set) var state = ChatState()
    
    public func sendMessage(text: String) async throws -> MessageId {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else { return }
            channelController.createNewMessage(text: text) { result in
                switch result {
                case let .success(messageId):
                    self.pendingMessageContinuations[messageId] = continuation
                case let .failure(error):
                    return continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func loadPreviousMessages() async throws {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else { return }
            channelController.loadPreviousMessages { error in
                print("===== query updated in the db \(Date())")
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
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
extension Chat: EventsControllerDelegate {
    public func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        if let newMessageEvent = event as? MessageNewEvent {
            let id = newMessageEvent.message.id
            let continuation = pendingMessageContinuations[id]
            continuation?.resume(returning: id)
            pendingMessageContinuations.removeValue(forKey: id)
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
