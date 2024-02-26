//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public final class ChatState: ObservableObject {
    private let cid: ChannelId
    private var channelObserver: EntityDatabaseObserverWrapper<ChatChannel, ChannelDTO>?
    let messageOrder: MessageOrdering
    
    init(cid: ChannelId, database: DatabaseContainer, messageOrder: MessageOrdering) {
        self.cid = cid
        self.messageOrder = messageOrder
        startObservingChannel(with: cid, in: database)
    }
    
    // MARK: Represented Channel
    
    // TODO: Exposing it as non-nil? Requires one DB fetch on Chat creation
    @Published private(set) var channel: ChatChannel?
    
    // MARK: Messages
    
    @Published public private(set) var messages: [ChatMessage] = []
    
    @MainActor func setMessages(_ messages: [ChatMessage]) {
        self.messages = messages
    }
}

// MARK: Observing the channel

@available(iOS 13.0, *)
extension ChatState {
    private func startObservingChannel(with cid: ChannelId, in database: DatabaseContainer) {
        channelObserver = { [weak self] in
            let observer = EntityDatabaseObserverWrapper(
                isBackground: true,
                database: database,
                fetchRequest: ChannelDTO.fetchRequest(for: cid),
                itemCreator: { try $0.asModel() as ChatChannel }
            ).onChange { [weak self] change in
                self?.channel = change.item
            }
            return observer
        }()
        do {
            try channelObserver?.startObserving()
        } catch {
            log.error("Failed to start the channel observer for \(cid)")
        }
    }
}
