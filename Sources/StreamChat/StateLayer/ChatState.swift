//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a ``ChatChannel`` and its state.
@available(iOS 13.0, *)
@MainActor public final class ChatState: ObservableObject {
    private let channelUpdater: ChannelUpdater
    private let dataStore: DataStore
    private let environment: Chat.Environment
    private var observer: Observer?
    private(set) var memberList: MemberList?
    private(set) var messageStates = NSMapTable<NSString, MessageState>(valueOptions: .weakMemory)
    private(set) var readStateSender: Chat.ReadStateSender?
    
    init(
        channelQuery: ChannelQuery,
        messageOrder: MessageOrdering,
        memberSorting: [Sorting<ChannelMemberListSortingKey>],
        channelUpdater: ChannelUpdater,
        client: ChatClient,
        environment: Chat.Environment
    ) {
        self.channelQuery = channelQuery
        self.channelUpdater = channelUpdater
        self.client = client
        dataStore = DataStore(database: client.databaseContainer)
        self.environment = environment
        self.memberSorting = memberSorting
        self.messageOrder = messageOrder
        
        if let cid = channelQuery.cid {
            observe(cid)
        }
    }
    
    /// The client instance the ``Chat`` was created with.
    public let client: ChatClient
    
    // MARK: - Represented Channel and Query
    
    /// The represented ``ChatChannel``.
    @Published public internal(set) var channel: ChatChannel?
    
    /// The channel query used for looking up the channel.
    public private(set) var channelQuery: ChannelQuery
    
    // MARK: - Members
    
    /// An array of loaded channel members.
    ///
    /// Use load members in ``Chat`` for loading more members.
    @Published public private(set) var members = StreamCollection<ChatChannelMember>([])
    
    /// The sorting order for channel members (the default sorting is by created at in ascending order).
    let memberSorting: [Sorting<ChannelMemberListSortingKey>]
    
    // MARK: - Messages
    
    /// Describes the ordering of messages.
    public let messageOrder: MessageOrdering
    
    /// An array of loaded messages.
    ///
    /// Messages are ordered by timestamp and ``messageOrder`` (In case of ``MessageOrdering/bottomToTop`` the list is sorted in ascending order).
    ///
    /// Use load messages in ``Chat`` for loading more messages.
    @Published public internal(set) var messages = StreamCollection<ChatMessage>([])
    
    /// Access a message which is available locally by its id.
    ///
    /// - Note: This method does a local lookup of the message and returns a message present in ``ChatState/messages``.
    ///
    /// - Parameter messageId: The id of the message which is available locally.
    ///
    /// - Returns: An instance of the locally available chat message
    public func localMessage(for messageId: MessageId) -> ChatMessage? {
        if let message = dataStore.message(id: messageId), message.cid == channelQuery.cid {
            return message
        }
        return nil
    }
    
    /// A Boolean value that returns whether the oldest messages have all been loaded or not.
    public var hasLoadedAllPreviousMessages: Bool {
        channelUpdater.paginationStateHandler.state.hasLoadedAllPreviousMessages
    }
    
    /// A Boolean value that returns whether the newest messages have all been loaded or not.
    public var hasLoadedAllNextMessages: Bool {
        channelUpdater.paginationStateHandler.state.hasLoadedAllNextMessages || messages.isEmpty
    }

    /// A Boolean value that returns whether the channel is currently in a mid-page.
    /// The value is false if the channel has the first page loaded.
    /// The value is true if the channel is in a mid fragment and didn't load the first page yet.
    public var isJumpingToMessage: Bool {
        channelUpdater.paginationStateHandler.state.isJumpingToMessage
    }

    /// A Boolean value that returns whether the channel is currently loading a page around a message.
    public var isLoadingMiddleMessages: Bool {
        channelUpdater.paginationStateHandler.state.isLoadingMiddleMessages
    }

    /// A Boolean value that returns whether the channel is currently loading next (new) messages.
    public var isLoadingNextMessages: Bool {
        channelUpdater.paginationStateHandler.state.isLoadingNextMessages
    }

    /// A Boolean value that returns whether the channel is currently loading previous (old) messages.
    public var isLoadingPreviousMessages: Bool {
        channelUpdater.paginationStateHandler.state.isLoadingPreviousMessages
    }
    
    // MARK: - Message Reading
    
    /// The id of the message which the current user last read.
    public var lastReadMessageId: MessageId? {
        guard let channel else { return nil }
        guard let userId = client.authenticationRepository.currentUserId else { return nil }
        return channel.lastReadMessageId(userId: userId)
    }
    
    /// The id of the first unread message.
    ///
    /// The returned message id follows requirements:
    /// * Read state is unavailable: oldest message if all the messages have been paginated, otherwise nil
    /// * Unread message count is zero: nil
    /// * Read state's ``ChatChannelRead/lastReadMessageId`` is nil: oldest message if all the messages have been paginated, otherwise nil
    /// * Last read message is unreachable (e.g. channel was truncated): oldest message if all the messages have been paginated, otherwise nil
    /// * Next message after the last read message id not from the current user
    public var firstUnreadMessageId: MessageId? {
        guard let userId = client.authenticationRepository.currentUserId else { return nil }
        return UnreadMessageLookup.firstUnreadMessage(in: self, userId: userId)
    }

    // MARK: - Throttling and Slow Mode
    
    /// The duration until the current user can't send new messages when the channel has slow mode enabled.
    ///
    /// - SeeAlso: ``Chat/enableSlowMode(cooldownDuration:)``
    /// - Returns: 0, if slow mode is not enabled, otherwise the remining cooldown duration in seconds.
    public var remainingCooldownDuration: Int {
        guard let channel else { return 0 }
        guard channel.cooldownDuration > 0 else { return 0 }
        guard !channel.ownCapabilities.contains(.skipSlowMode) else { return 0 }
        guard let lastMessageTimestamp = channel.lastMessageFromCurrentUser?.createdAt else { return 0 }
        let currentTime = Date().timeIntervalSince(lastMessageTimestamp)
        return max(0, channel.cooldownDuration - Int(currentTime))
    }
    
    // MARK: - Watchers
    
    /// An array of users who are currently watching the channel.
    ///
    /// Use load watchers method in ``Chat`` for populating this array.
    @Published public internal(set) var watchers = StreamCollection<ChatUser>([])
}

// MARK: - Internal

@available(iOS 13.0, *)
extension ChatState {
    func setChannelId(_ channelId: ChannelId) {
        channelQuery = ChannelQuery(cid: channelId, channelQuery: channelQuery)
        observe(channelId)
    }
    
    func observe(_ channelId: ChannelId) {
        let memberList = MemberList(
            query: ChannelMemberListQuery(
                cid: channelId,
                sort: memberSorting
            ),
            client: client
        )
        self.memberList = memberList
        readStateSender = environment.readStateSenderBuilder(
            channelId,
            channelUpdater,
            client.authenticationRepository,
            client.messageRepository
        )
        observer = Observer(
            cid: channelId,
            channelQuery: channelQuery,
            clientConfig: client.config,
            messageOrder: messageOrder,
            memberListState: memberList.state,
            database: client.databaseContainer,
            eventNotificationCenter: client.eventNotificationCenter
        )
        if let observer {
            let initial = observer.start(
                with: .init(
                    channelDidChange: { [weak self] in self?.channel = $0 },
                    membersDidChange: { [weak self] in self?.members = $0 },
                    messagesDidChange: { [weak self] in self?.messages = $0 },
                    watchersDidChange: { [weak self] in self?.watchers = $0 }
                )
            )
            channel = initial.channel
            members = initial.members
            messages = initial.messages
            watchers = initial.watchers
        }
    }
    
    func messageState(for messageId: MessageId, messageUpdater: MessageUpdater) async throws -> MessageState {
        if let state = messageStates.object(forKey: messageId as NSString) {
            return state
        } else {
            let message: ChatMessage
            if let localMessage = localMessage(for: messageId) {
                message = localMessage
            } else {
                guard let cid = channelQuery.cid else { throw ClientError.ChannelNotCreatedYet() }
                message = try await messageUpdater.getMessage(cid: cid, messageId: messageId)
            }
            let state = MessageState(
                message: message,
                messageOrder: messageOrder,
                database: client.databaseContainer,
                clientConfig: client.config,
                replyPaginationHandler: MessagesPaginationStateHandler()
            )
            messageStates.setObject(state, forKey: messageId as NSString)
            return state
        }
    }
}
