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
                itemCreator: { try $0.asModel() }
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
                itemCreator: { try $0.asModel() },
                sorting: []
            )
            watchersObserver = StateLayerDatabaseObserver(
                databaseContainer: database,
                fetchRequest: UserDTO.watcherFetchRequest(cid: cid),
                itemCreator: { try $0.asModel() },
                sorting: []
            )
            self.eventNotificationCenter = eventNotificationCenter
        }
        
        struct Handlers {
            let channelDidChange: (ChatChannel?) async -> Void
            let membersDidChange: (StreamCollection<ChatChannelMember>) async -> Void
            let messagesDidChange: (StreamCollection<ChatMessage>) async -> Void
            let watchersDidChange: (StreamCollection<ChatUser>) async -> Void
        }
        
        @MainActor func start(
            with handlers: Handlers
        ) -> (
            channel: ChatChannel?,
            members: StreamCollection<ChatChannelMember>,
            messages: StreamCollection<ChatMessage>,
            watchers: StreamCollection<ChatUser>
        ) {
            memberListObserver = memberListState.$members
                .dropFirst()
                .sink(receiveValue: { change in
                    Task.mainActor { await handlers.membersDidChange(change) }
                })
            
            do {
                let channel = try channelObserver.startObserving(didChange: handlers.channelDidChange)
                let messages = try messagesObserver.startObserving(didChange: handlers.messagesDidChange)
                let watchers = try watchersObserver.startObserving(didChange: handlers.watchersDidChange)
                return (channel, memberListState.members, messages, watchers)
            } catch {
                log.error("Failed to start the observers for cid: \(cid) with error \(error)")
                return (nil, StreamCollection([]), StreamCollection([]), StreamCollection([]))
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
