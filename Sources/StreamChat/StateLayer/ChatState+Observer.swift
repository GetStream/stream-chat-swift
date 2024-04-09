//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@available(iOS 13.0, *)
extension ChatState {
    final class Observer {
        private let cid: ChannelId
        private let eventNotificationCenter: EventNotificationCenter
        private var memberListObserver: AnyCancellable?
        
        let channelObserver: StateLayerDatabaseObserver<EntityResult, ChatChannel, ChannelDTO>
        let memberListState: MemberListState
        let messagesObserver: StateLayerDatabaseObserver<ListResult, ChatMessage, MessageDTO>
        let watchersObserver: StateLayerDatabaseObserver<ListResult, ChatUser, UserDTO>
        
        init(
            cid: ChannelId,
            channelQuery: ChannelQuery,
            clientConfig: ChatClientConfig,
            messageOrder: MessageOrdering,
            memberListState: MemberListState,
            database: DatabaseContainer,
            eventNotificationCenter: EventNotificationCenter
        ) {
            self.cid = cid
            self.memberListState = memberListState
            channelObserver = StateLayerDatabaseObserver(
                databaseContainer: database,
                fetchRequest: ChannelDTO.fetchRequest(for: cid),
                itemCreator: { try $0.asModel() as ChatChannel }
            )
            messagesObserver = StateLayerDatabaseObserver(
                databaseContainer: database,
                fetchRequest: MessageDTO.messagesFetchRequest(
                    for: cid,
                    pageSize: channelQuery.pagination?.pageSize ?? .messagesPageSize,
                    sortAscending: messageOrder.isAscending,
                    deletedMessagesVisibility: clientConfig.deletedMessagesVisibility,
                    shouldShowShadowedMessages: clientConfig.shouldShowShadowedMessages
                ),
                itemCreator: { try $0.asModel() as ChatMessage },
                sorting: []
            )
            watchersObserver = StateLayerDatabaseObserver(
                databaseContainer: database,
                fetchRequest: UserDTO.watcherFetchRequest(cid: cid),
                itemCreator: { try $0.asModel() as ChatUser },
                sorting: []
            )
            self.eventNotificationCenter = eventNotificationCenter
        }
        
        struct Handlers {
            let channelDidChange: (ChatChannel?) async -> Void
            let membersDidChange: (StreamCollection<ChatChannelMember>) async -> Void
            let messagesDidChange: (StreamCollection<ChatMessage>) async -> Void
            let typingUsersDidChange: (Set<ChatUser>) async -> Void
            let watchersDidChange: (StreamCollection<ChatUser>) async -> Void
        }
        
        func start(with handlers: Handlers) {
            memberListObserver = memberListState.$members
                .dropFirst() // skip initial
                .sink(receiveValue: { change in Task { await handlers.membersDidChange(change) } })
            
            do {
                var lastTypingUsers: Set<ChatUser>?
                try channelObserver.startObserving(didChange: { channel in
                    let currentlyTypingUsers: Set<ChatUser> = channel?.currentlyTypingUsers ?? Set()
                    if lastTypingUsers != currentlyTypingUsers {
                        lastTypingUsers = currentlyTypingUsers
                        await handlers.typingUsersDidChange(currentlyTypingUsers)
                    }
                    await handlers.channelDidChange(channel)
                })
            } catch {
                log.error("Failed to start the channel observer for cid: \(cid)")
            }
            do {
                try messagesObserver.startObserving(didChange: handlers.messagesDidChange)
            } catch {
                log.error("Failed to start the messages observer for cid: \(cid)")
            }
            do {
                try watchersObserver.startObserving(didChange: handlers.watchersDidChange)
            } catch {
                log.error("Failed to start the watchers observer for cid: \(cid)")
            }
        }
    }
}

extension MessageOrdering {
    var isAscending: Bool {
        switch self {
        case .topToBottom:
            return false
        case .bottomToTop:
            return true
        }
    }
}
