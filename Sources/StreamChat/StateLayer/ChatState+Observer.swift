//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

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
                database: database,
                fetchRequest: ChannelDTO.fetchRequest(for: cid),
                itemCreator: { try $0.asModel() }
            )
            messagesObserver = StateLayerDatabaseObserver(
                database: database,
                fetchRequest: MessageDTO.messagesFetchRequest(
                    for: cid,
                    pageSize: channelQuery.pagination?.pageSize ?? .messagesPageSize,
                    sortAscending: messageOrder.isAscending,
                    deletedMessagesVisibility: clientConfig.deletedMessagesVisibility,
                    shouldShowShadowedMessages: clientConfig.shouldShowShadowedMessages
                ),
                itemCreator: { try $0.asModel() },
                itemReuseKeyPaths: (\ChatMessage.id, \MessageDTO.id),
                sorting: []
            )
            watchersObserver = StateLayerDatabaseObserver(
                database: database,
                fetchRequest: UserDTO.watcherFetchRequest(cid: cid),
                itemCreator: { try $0.asModel() },
                itemReuseKeyPaths: (\ChatUser.id, \UserDTO.id),
                sorting: []
            )
            self.eventNotificationCenter = eventNotificationCenter
        }
        
        struct Handlers {
            let channelDidChange: @MainActor(ChatChannel?) async -> Void
            let membersDidChange: @MainActor(StreamCollection<ChatChannelMember>) async -> Void
            let messagesDidChange: @MainActor(StreamCollection<ChatMessage>) async -> Void
            let watchersDidChange: @MainActor(StreamCollection<ChatUser>) async -> Void
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
