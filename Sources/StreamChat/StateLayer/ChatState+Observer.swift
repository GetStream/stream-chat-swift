//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension ChatState {
    final class Observer {
        private let cid: ChannelId
        private let channelObserver: BackgroundEntityDatabaseObserver<ChatChannel, ChannelDTO>
        private let eventNotificationCenter: EventNotificationCenter
        private let messagesObserver: BackgroundListDatabaseObserver<ChatMessage, MessageDTO>
        private let watchersObserver: BackgroundListDatabaseObserver<ChatUser, UserDTO>
        private var webSocketEventObservers = [EventObserver]()
        
        init(cid: ChannelId, channelQuery: ChannelQuery, database: DatabaseContainer, eventNotificationCenter: EventNotificationCenter) {
            // TODO: Feasability of using context did change notification instead of FRC based observers
            // Note: Ordering and filtering is dependent on DB
            self.cid = cid
            let context = database.backgroundReadOnlyContext
            channelObserver = BackgroundEntityDatabaseObserver(
                context: context,
                fetchRequest: ChannelDTO.fetchRequest(for: cid),
                itemCreator: { try $0.asModel() as ChatChannel }
            )
            messagesObserver = BackgroundListDatabaseObserver(
                context: context,
                fetchRequest: MessageDTO.messagesFetchRequest(
                    for: cid,
                    pageSize: channelQuery.pagination?.pageSize ?? .messagesPageSize,
                    sortAscending: true,
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
            let messagesDidChange: ([ListChange<ChatMessage>]) async -> Void
            let typingUsersDidChange: (Set<ChatUser>) async -> Void
            let watchersDidChange: ([ListChange<ChatUser>]) async -> Void
        }
        
        func start(with handlers: Handlers) {
            channelObserver.onChange(do: { change in Task { await handlers.channelDidChange(change.item) } })
            channelObserver.onFieldChange(\.currentlyTypingUsers, do: { change in Task { await handlers.typingUsersDidChange(change.item) } })
            messagesObserver.onDidChange = { changes in Task { await handlers.messagesDidChange(changes) } }
            watchersObserver.onDidChange = { changes in Task { await handlers.watchersDidChange(changes) } }
            
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
