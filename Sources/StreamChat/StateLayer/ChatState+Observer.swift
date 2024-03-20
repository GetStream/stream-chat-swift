//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@available(iOS 13.0, *)
extension ChatState {
    final class Observer {
        private let cid: ChannelId
        private let channelObserver: BackgroundEntityDatabaseObserver<ChatChannel, ChannelDTO>
        private let eventNotificationCenter: EventNotificationCenter
        private let memberListState: MemberListState
        private var memberListObserver: AnyCancellable?
        private let messagesObserver: BackgroundListDatabaseObserver<ChatMessage, MessageDTO>
        private let watchersObserver: BackgroundListDatabaseObserver<ChatUser, UserDTO>
        private var webSocketEventObservers = [EventObserver]()
        
        init(
            cid: ChannelId,
            channelQuery: ChannelQuery,
            messageOrder: MessageOrdering,
            memberListState: MemberListState,
            database: DatabaseContainer,
            eventNotificationCenter: EventNotificationCenter
        ) {
            self.cid = cid
            self.memberListState = memberListState
            let context = database.backgroundReadOnlyContext
            channelObserver = BackgroundEntityDatabaseObserver(
                context: context,
                fetchRequest: ChannelDTO.fetchRequest(for: cid),
                itemCreator: { try $0.asModel() as ChatChannel }
            )
            messagesObserver = BackgroundListDatabaseObserver(
                context: database.backgroundReadOnlyContext,
                fetchRequest: MessageDTO.messagesFetchRequest(
                    for: cid,
                    pageSize: channelQuery.pagination?.pageSize ?? .messagesPageSize,
                    sortAscending: messageOrder.isAscending,
                    deletedMessagesVisibility: context.deletedMessagesVisibility ?? .visibleForCurrentUser,
                    shouldShowShadowedMessages: context.shouldShowShadowedMessages ?? false
                ),
                itemCreator: { try $0.asModel() as ChatMessage },
                sorting: []
            )
            watchersObserver = BackgroundListDatabaseObserver(
                context: context,
                fetchRequest: UserDTO.watcherFetchRequest(cid: cid),
                itemCreator: { try $0.asModel() as ChatUser },
                sorting: []
            )
            self.eventNotificationCenter = eventNotificationCenter
        }
        
        struct Handlers {
            let channelDidChange: (ChatChannel) async -> Void
            let membersDidChange: (StreamCollection<ChatChannelMember>) async -> Void
            let messagesDidChange: (StreamCollection<ChatMessage>) async -> Void
            let typingUsersDidChange: (Set<ChatUser>) async -> Void
            let watchersDidChange: (StreamCollection<ChatUser>) async -> Void
        }
        
        func start(with handlers: Handlers) {
            channelObserver.onChange(do: { change in Task { await handlers.channelDidChange(change.item) } })
            channelObserver.onFieldChange(\.currentlyTypingUsers, do: { change in Task { await handlers.typingUsersDidChange(change.item) } })
            memberListObserver = memberListState.$members.sink(receiveValue: { change in Task { await handlers.membersDidChange(change) } })
            messagesObserver.onDidChange = { [weak messagesObserver] _ in
                guard let items = messagesObserver?.items else { return }
                let collection = StreamCollection(items)
                Task { await handlers.messagesDidChange(collection) }
            }
            watchersObserver.onDidChange = { [weak watchersObserver] _ in
                guard let items = watchersObserver?.items else { return }
                let collection = StreamCollection(items)
                Task { await handlers.watchersDidChange(collection) }
            }
            
            // TODO: Implement member list
//            if let eventNotificationCenter {
//                webSocketEventObservers = [
//                    MemberEventObserver(notificationCenter: eventNotificationCenter, cid: cid) { event in Task {  } }
//                ]
//            }
            
            do {
                try channelObserver.startObserving()
            } catch {
                log.error("Failed to start the channel observer for cid: \(cid)")
            }
            do {
                try messagesObserver.startObserving()
            } catch {
                log.error("Failed to start the messages observer for cid: \(cid)")
            }
            do {
                try watchersObserver.startObserving()
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
