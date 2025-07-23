//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A controller for managing livestream channels that operates without local database persistence.
/// Unlike `ChatChannelController`, this controller manages all data in memory and communicates directly with the API.
public class LivestreamChannelController: EventsControllerDelegate {
    // MARK: - Public Properties
    
    /// The ChannelQuery this controller observes.
    @Atomic public private(set) var channelQuery: ChannelQuery
    
    /// The identifier of a channel this controller observes.
    public var cid: ChannelId? { channelQuery.cid }
    
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient
    
    /// The channel the controller represents.
    /// This is managed in memory and updated via API calls.
    @Atomic public private(set) var channel: ChatChannel?
    
    /// The messages of the channel the controller represents.
    /// This is managed in memory and updated via API calls.
    @Atomic public private(set) var messages: [ChatMessage] = []
    
    /// A Boolean value that returns whether the oldest messages have all been loaded or not.
    public var hasLoadedAllPreviousMessages: Bool {
        paginationStateHandler.state.hasLoadedAllPreviousMessages
    }
    
    /// A Boolean value that returns whether the newest messages have all been loaded or not.
    public var hasLoadedAllNextMessages: Bool {
        paginationStateHandler.state.hasLoadedAllNextMessages || messages.isEmpty
    }
    
    /// A Boolean value that returns whether the channel is currently loading previous (old) messages.
    public var isLoadingPreviousMessages: Bool {
        paginationStateHandler.state.isLoadingPreviousMessages
    }
    
    /// A Boolean value that returns whether the channel is currently loading next (new) messages.
    public var isLoadingNextMessages: Bool {
        paginationStateHandler.state.isLoadingNextMessages
    }
    
    /// A Boolean value that returns whether the channel is currently loading a page around a message.
    public var isLoadingMiddleMessages: Bool {
        paginationStateHandler.state.isLoadingMiddleMessages
    }
    
    /// A Boolean value that returns whether the channel is currently in a mid-page.
    public var isJumpingToMessage: Bool {
        paginationStateHandler.state.isJumpingToMessage
    }
    
    /// The id of the first unread message for the current user.
    public var firstUnreadMessageId: MessageId? {
        channel.flatMap { getFirstUnreadMessageId(for: $0) }
    }
    
    /// The id of the message which the current user last read.
    public var lastReadMessageId: MessageId? {
        client.currentUserId.flatMap { channel?.lastReadMessageId(userId: $0) }
    }
    
    /// Set the delegate to observe the changes in the system.
    public weak var delegate: LivestreamChannelControllerDelegate?
    
    // MARK: - Private Properties
    
    /// The API client for making direct API calls
    private let apiClient: APIClient
    
    /// Pagination state handler for managing message pagination
    private let paginationStateHandler: MessagesPaginationStateHandling
    
    /// Events controller for listening to real-time events
    private let eventsController: EventsController
    
    /// Flag indicating whether channel is created on backend
    private var isChannelAlreadyCreated: Bool
    
    /// Current user ID for convenience
    private var currentUserId: UserId? { client.currentUserId }
    
    // MARK: - Initialization
    
    /// Creates a new `LivestreamChannelController`
    /// - Parameters:
    ///   - channelQuery: channel query for observing changes
    ///   - client: The `Client` this controller belongs to.
    ///   - isChannelAlreadyCreated: Flag indicating whether channel is created on backend.
    public init(
        channelQuery: ChannelQuery,
        client: ChatClient,
        isChannelAlreadyCreated: Bool = true
    ) {
        self.channelQuery = channelQuery
        self.client = client
        apiClient = client.apiClient
        self.isChannelAlreadyCreated = isChannelAlreadyCreated
        paginationStateHandler = MessagesPaginationStateHandler()
        eventsController = client.eventsController()
        
        // Set up events delegate to listen for real-time events
        eventsController.delegate = self
    }
    
    // MARK: - Public Methods
    
    /// Synchronizes the controller with the backend data
    /// - Parameter completion: Called when the synchronization is finished
    public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        updateChannelData(
            channelQuery: channelQuery,
            completion: completion
        )
    }
    
    /// Loads previous messages from backend.
    /// - Parameters:
    ///   - messageId: ID of the last fetched message. You will get messages `older` than the provided ID.
    ///   - limit: Limit for page size. By default it is 25.
    ///   - completion: Called when the network request is finished.
    public func loadPreviousMessages(
        before messageId: MessageId? = nil,
        limit: Int? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard cid != nil, isChannelAlreadyCreated else {
            completion?(ClientError.ChannelNotCreatedYet())
            return
        }
        
        let messageId = messageId ?? paginationStateHandler.state.oldestFetchedMessage?.id ?? lastLocalMessageId()
        guard let messageId = messageId else {
            completion?(ClientError.ChannelEmptyMessages())
            return
        }
        
        guard !hasLoadedAllPreviousMessages && !isLoadingPreviousMessages else {
            completion?(nil)
            return
        }
        
        let limit = limit ?? channelQuery.pagination?.pageSize ?? .messagesPageSize
        var query = channelQuery
        query.pagination = MessagesPagination(pageSize: limit, parameter: .lessThan(messageId))
        
        updateChannelData(channelQuery: query, completion: completion)
    }
    
    /// Loads next messages from backend.
    /// - Parameters:
    ///   - messageId: ID of the current first message. You will get messages `newer` than the provided ID.
    ///   - limit: Limit for page size. By default it is 25.
    ///   - completion: Called when the network request is finished.
    public func loadNextMessages(
        after messageId: MessageId? = nil,
        limit: Int? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard cid != nil, isChannelAlreadyCreated else {
            completion?(ClientError.ChannelNotCreatedYet())
            return
        }
        
        let messageId = messageId ?? paginationStateHandler.state.newestFetchedMessage?.id ?? messages.first?.id
        guard let messageId = messageId else {
            completion?(ClientError.ChannelEmptyMessages())
            return
        }
        
        guard !hasLoadedAllNextMessages && !isLoadingNextMessages else {
            completion?(nil)
            return
        }
        
        let limit = limit ?? channelQuery.pagination?.pageSize ?? .messagesPageSize
        var query = channelQuery
        query.pagination = MessagesPagination(pageSize: limit, parameter: .greaterThan(messageId))
        
        updateChannelData(channelQuery: query, completion: completion)
    }
    
    /// Load messages around the given message id.
    /// - Parameters:
    ///   - messageId: The message id of the message to jump to.
    ///   - limit: The number of messages to load in total, including the message to jump to.
    ///   - completion: Callback when the API call is completed.
    public func loadPageAroundMessageId(
        _ messageId: MessageId,
        limit: Int? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard isChannelAlreadyCreated else {
            completion?(ClientError.ChannelNotCreatedYet())
            return
        }
        
        guard !isLoadingMiddleMessages else {
            completion?(nil)
            return
        }
        
        let limit = limit ?? channelQuery.pagination?.pageSize ?? .messagesPageSize
        var query = channelQuery
        query.pagination = MessagesPagination(pageSize: limit, parameter: .around(messageId))
        
        updateChannelData(channelQuery: query, completion: completion)
    }
    
    /// Cleans the current state and loads the first page again.
    /// - Parameter completion: Callback when the API call is completed.
    public func loadFirstPage(_ completion: ((_ error: Error?) -> Void)? = nil) {
        var query = channelQuery
        query.pagination = .init(
            pageSize: channelQuery.pagination?.pageSize ?? .messagesPageSize,
            parameter: nil
        )
        
        // Clear current messages when loading first page
        messages = []
        
        updateChannelData(channelQuery: query, completion: completion)
    }
    
    // MARK: - Helper Methods
    
    public func getFirstUnreadMessageId(for channel: ChatChannel) -> MessageId? {
        UnreadMessageLookup.firstUnreadMessageId(
            in: channel,
            messages: StreamCollection(messages),
            hasLoadedAllPreviousMessages: hasLoadedAllPreviousMessages,
            currentUserId: client.currentUserId
        )
    }
    
    // MARK: - Private Methods
    
    private func updateChannelData(
        channelQuery: ChannelQuery,
        completion: ((Error?) -> Void)? = nil
    ) {
        if let pagination = channelQuery.pagination {
            paginationStateHandler.begin(pagination: pagination)
        }
        
        let isChannelCreate = !isChannelAlreadyCreated
        let endpoint: Endpoint<ChannelPayload> = isChannelCreate ?
            .createChannel(query: channelQuery) :
            .updateChannel(query: channelQuery)
        
        let requestCompletion: (Result<ChannelPayload, Error>) -> Void = { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                switch result {
                case .success(let payload):
                    self.handleChannelPayload(payload, channelQuery: channelQuery)
                    completion?(nil)

                case .failure(let error):
                    if let pagination = channelQuery.pagination {
                        self.paginationStateHandler.end(pagination: pagination, with: .failure(error))
                    }
                    completion?(error)
                }
            }
        }
        
        apiClient.request(endpoint: endpoint, completion: requestCompletion)
    }
    
    private func handleChannelPayload(_ payload: ChannelPayload, channelQuery: ChannelQuery) {
        // Update pagination state
        if let pagination = channelQuery.pagination {
            paginationStateHandler.end(pagination: pagination, with: .success(payload.messages))
        }
        
        // Mark channel as created if it was a create operation
        if !isChannelAlreadyCreated {
            isChannelAlreadyCreated = true
            // Update the channel query with the actual cid if it was generated
            self.channelQuery = ChannelQuery(cid: payload.channel.cid, channelQuery: channelQuery)
        }
        
        // Convert payloads to models
        let newChannel = mapChannelPayload(payload)
        // Update channel
        let oldChannel = channel
        channel = newChannel

        let newMessages = payload.messages.compactMap { mapMessagePayload($0, cid: payload.channel.cid) }
        
        // Update messages based on pagination type
        updateMessagesArray(with: newMessages, pagination: channelQuery.pagination)
        
        // Notify delegate
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if oldChannel != nil {
                self.delegate?.livestreamChannelController(self, didUpdateChannel: .update(newChannel))
            } else {
                self.delegate?.livestreamChannelController(self, didUpdateChannel: .create(newChannel))
            }
            
            self.delegate?.livestreamChannelController(self, didUpdateMessages: self.messages)
        }
    }
    
    private func updateMessagesArray(with newMessages: [ChatMessage], pagination: MessagesPagination?) {
        let newMessages = Array(newMessages.reversed())
        switch pagination?.parameter {
        case .lessThan, .lessThanOrEqual:
            // Loading older messages - append to end
            messages.append(contentsOf: newMessages)
            
        case .greaterThan, .greaterThanOrEqual:
            // Loading newer messages - insert at beginning
            messages.insert(contentsOf: newMessages, at: 0)
            
        case .around, .none:
            // Loading around a message or first page - replace all
            messages = newMessages
        }
    }
    
    private func mapChannelPayload(_ payload: ChannelPayload) -> ChatChannel {
        let channelPayload = payload.channel
        
        // Map members
        let members = payload.members.compactMap { mapMemberPayload($0, channelId: channelPayload.cid) }
        
        // Map latest messages
        let latestMessages = payload.messages.prefix(5).compactMap { mapMessagePayload($0, cid: channelPayload.cid) }
        
        // Map reads
        let reads = payload.channelReads.compactMap { mapChannelReadPayload($0) }
        
        // Map watchers
        let watchers = payload.watchers?.compactMap { mapUserPayload($0) } ?? []
        
        // Map typing users (empty for livestream)
        let typingUsers: Set<ChatUser> = []
        
        return ChatChannel(
            cid: channelPayload.cid,
            name: channelPayload.name,
            imageURL: channelPayload.imageURL,
            lastMessageAt: channelPayload.lastMessageAt,
            createdAt: channelPayload.createdAt,
            updatedAt: channelPayload.updatedAt,
            deletedAt: channelPayload.deletedAt,
            truncatedAt: channelPayload.truncatedAt,
            isHidden: payload.isHidden ?? false,
            createdBy: channelPayload.createdBy.flatMap { mapUserPayload($0) },
            config: channelPayload.config,
            ownCapabilities: Set(channelPayload.ownCapabilities?.compactMap { ChannelCapability(rawValue: $0) } ?? []),
            isFrozen: channelPayload.isFrozen,
            isDisabled: channelPayload.isDisabled,
            isBlocked: channelPayload.isBlocked ?? false,
            lastActiveMembers: Array(members.prefix(100)),
            membership: payload.membership.flatMap { mapMemberPayload($0, channelId: channelPayload.cid) },
            currentlyTypingUsers: typingUsers,
            lastActiveWatchers: Array(watchers.prefix(100)),
            team: channelPayload.team,
            unreadCount: ChannelUnreadCount(messages: 0, mentions: 0), // Default values for livestream
            watcherCount: payload.watcherCount ?? 0,
            memberCount: channelPayload.memberCount,
            reads: reads,
            cooldownDuration: channelPayload.cooldownDuration,
            extraData: channelPayload.extraData,
            latestMessages: latestMessages,
            lastMessageFromCurrentUser: latestMessages.first { $0.isSentByCurrentUser },
            pinnedMessages: payload.pinnedMessages.compactMap { mapMessagePayload($0, cid: channelPayload.cid) },
            muteDetails: nil, // Default value
            previewMessage: latestMessages.first,
            draftMessage: nil, // Default value for livestream
            activeLiveLocations: [] // Default value
        )
    }
    
    private func mapMessagePayload(_ payload: MessagePayload, cid: ChannelId) -> ChatMessage? {
        let author = mapUserPayload(payload.user)
        let mentionedUsers = Set(payload.mentionedUsers.compactMap { mapUserPayload($0) })
        let threadParticipants = payload.threadParticipants.compactMap { mapUserPayload($0) }
        
        // Map quoted message recursively
        let quotedMessage = payload.quotedMessage.flatMap { mapMessagePayload($0, cid: cid) }
        
        // Map reactions
        let latestReactions = Set(payload.latestReactions.compactMap { mapReactionPayload($0) })
        let currentUserReactions = Set(payload.ownReactions.compactMap { mapReactionPayload($0) })
        
        // Map attachments
        let attachments: [AnyChatMessageAttachment] = payload.attachments
            .enumerated()
            .compactMap { offset, attachmentPayload in
                guard let payloadData = try? JSONEncoder.stream.encode(attachmentPayload.payload) else {
                    return nil
                }
                return AnyChatMessageAttachment(
                    id: .init(cid: cid, messageId: payload.id, index: offset),
                    type: attachmentPayload.type,
                    payload: payloadData,
                    downloadingState: nil,
                    uploadingState: nil
                )
            }

        let reads = channel?.reads ?? []
        let createdAtInterval = payload.createdAt.timeIntervalSince1970
        let messageUserId = payload.user.id
        let readBy = reads.filter { read in
            read.user.id != messageUserId && read.lastReadAt.timeIntervalSince1970 >= createdAtInterval
        }
        debugPrint("reads", reads, "readBy", readBy)

        return ChatMessage(
            id: payload.id,
            cid: cid,
            text: payload.text,
            type: payload.type,
            command: payload.command,
            createdAt: payload.createdAt,
            locallyCreatedAt: nil,
            updatedAt: payload.updatedAt,
            deletedAt: payload.deletedAt,
            arguments: payload.args,
            parentMessageId: payload.parentId,
            showReplyInChannel: payload.showReplyInChannel,
            replyCount: payload.replyCount,
            extraData: payload.extraData,
            quotedMessage: quotedMessage,
            isBounced: false,
            // TODO: handle bounce
            isSilent: payload.isSilent,
            isShadowed: payload.isShadowed,
            reactionScores: payload.reactionScores,
            reactionCounts: payload.reactionCounts,
            reactionGroups: [:],
            author: author,
            mentionedUsers: mentionedUsers,
            threadParticipants: threadParticipants,
            attachments: attachments,
            latestReplies: [],
            localState: nil,
            isFlaggedByCurrentUser: false,
            latestReactions: latestReactions,
            currentUserReactions: currentUserReactions,
            isSentByCurrentUser: payload.user.id == currentUserId,
            pinDetails: payload.pinned ? MessagePinDetails(
                pinnedAt: payload.pinnedAt ?? payload.createdAt,
                pinnedBy: payload.pinnedBy.flatMap { mapUserPayload($0) } ?? author,
                expiresAt: payload.pinExpires
            ) : nil,
            translations: payload.translations,
            originalLanguage: payload.originalLanguage.flatMap { TranslationLanguage(languageCode: $0)
            },
            moderationDetails: nil,
            // TODO: handle moderation
            readBy: Set(readBy.map(\.user)),
            poll: nil,
            // TODO: handle polls
            textUpdatedAt: payload.messageTextUpdatedAt,
            draftReply: nil,
            // TODO: handle
            reminder: payload.reminder.map {
                .init(
                    remindAt: $0.remindAt,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            },
            sharedLocation: payload.location.map {
                .init(
                    messageId: $0.messageId,
                    channelId: cid,
                    userId: $0.userId,
                    createdByDeviceId: $0.createdByDeviceId,
                    latitude: $0.latitude,
                    longitude: $0.longitude,
                    updatedAt: $0.updatedAt,
                    createdAt: $0.createdAt,
                    endAt: $0.endAt
                )
            }
        )
    }
    
    private func mapUserPayload(_ payload: UserPayload) -> ChatUser {
        ChatUser(
            id: payload.id,
            name: payload.name,
            imageURL: payload.imageURL,
            isOnline: payload.isOnline,
            isBanned: payload.isBanned,
            isFlaggedByCurrentUser: false,
            userRole: UserRole(rawValue: payload.role.rawValue),
            teamsRole: payload.teamsRole?.mapValues { UserRole(rawValue: $0.rawValue) },
            createdAt: payload.createdAt,
            updatedAt: payload.updatedAt,
            deactivatedAt: payload.deactivatedAt,
            lastActiveAt: payload.lastActiveAt,
            teams: Set(payload.teams),
            language: payload.language.flatMap { TranslationLanguage(languageCode: $0) },
            extraData: payload.extraData
        )
    }
    
    private func mapMemberPayload(_ payload: MemberPayload, channelId: ChannelId) -> ChatChannelMember? {
        guard let userPayload = payload.user else { return nil }
        let user = mapUserPayload(userPayload)
        
        return ChatChannelMember(
            id: user.id,
            name: user.name,
            imageURL: user.imageURL,
            isOnline: user.isOnline,
            isBanned: user.isBanned,
            isFlaggedByCurrentUser: user.isFlaggedByCurrentUser,
            userRole: user.userRole,
            teamsRole: user.teamsRole,
            userCreatedAt: user.userCreatedAt,
            userUpdatedAt: user.userUpdatedAt,
            deactivatedAt: user.userDeactivatedAt,
            lastActiveAt: user.lastActiveAt,
            teams: user.teams,
            language: user.language,
            extraData: user.extraData,
            memberRole: MemberRole(rawValue: payload.role?.rawValue ?? "member"),
            memberCreatedAt: payload.createdAt,
            memberUpdatedAt: payload.updatedAt,
            isInvited: payload.isInvited ?? false,
            inviteAcceptedAt: payload.inviteAcceptedAt,
            inviteRejectedAt: payload.inviteRejectedAt,
            archivedAt: payload.archivedAt,
            pinnedAt: payload.pinnedAt,
            isBannedFromChannel: payload.isBanned ?? false,
            banExpiresAt: payload.banExpiresAt,
            isShadowBannedFromChannel: payload.isShadowBanned ?? false,
            notificationsMuted: payload.notificationsMuted,
            memberExtraData: [:]
        )
    }
    
    private func mapChannelReadPayload(_ payload: ChannelReadPayload) -> ChatChannelRead {
        ChatChannelRead(
            lastReadAt: payload.lastReadAt,
            lastReadMessageId: payload.lastReadMessageId,
            unreadMessagesCount: payload.unreadMessagesCount,
            user: mapUserPayload(payload.user)
        )
    }
    
    private func mapReactionPayload(_ payload: MessageReactionPayload) -> ChatMessageReaction? {
        ChatMessageReaction(
            id: "\(payload.type.rawValue)_\(payload.user.id)",
            type: payload.type,
            score: payload.score,
            createdAt: payload.createdAt,
            updatedAt: payload.updatedAt,
            author: mapUserPayload(payload.user),
            extraData: payload.extraData
        )
    }
    
    private func lastLocalMessageId() -> MessageId? {
        messages.last?.id
    }
    
    // MARK: - EventsControllerDelegate
    
    public func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        guard let channelEvent = event as? ChannelSpecificEvent, channelEvent.cid == cid else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.handleChannelEvent(event)
        }
    }
    
    // MARK: - Private Event Handling
    
    private func handleChannelEvent(_ event: Event) {
        switch event {
        case let messageNewEvent as MessageNewEvent:
            handleNewMessage(messageNewEvent.message)

        case let localMessageNewEvent as NewMessagePendingEvent:
            handleNewMessage(localMessageNewEvent.message)

        case let messageUpdatedEvent as MessageUpdatedEvent:
            handleUpdatedMessage(messageUpdatedEvent.message)
            
        case let messageDeletedEvent as MessageDeletedEvent:
            handleDeletedMessage(messageDeletedEvent.message)
            
        case let messageReadEvent as MessageReadEvent:
            handleMessageRead(messageReadEvent)
            
        case let reactionNewEvent as ReactionNewEvent:
            handleNewReaction(reactionNewEvent)
            
        case let reactionUpdatedEvent as ReactionUpdatedEvent:
            handleUpdatedReaction(reactionUpdatedEvent)
            
        case let reactionDeletedEvent as ReactionDeletedEvent:
            handleDeletedReaction(reactionDeletedEvent)
            
        default:
            // Ignore other events for now
            break
        }
    }
    
    private func handleNewMessage(_ message: ChatMessage) {
        // Add new message to the beginning of the array (newest first)
        var currentMessages = messages
        
        // Check if message already exists to avoid duplicates
        if currentMessages.contains(where: { $0.id == message.id }) {
            handleUpdatedMessage(message)
            return
        }

        currentMessages.insert(message, at: 0)
        messages = currentMessages

        // Notify delegate
        notifyDelegateOfChanges()
    }
    
    private func handleUpdatedMessage(_ updatedMessage: ChatMessage) {
        var currentMessages = messages
        
        // Find and update the message
        if let index = currentMessages.firstIndex(where: { $0.id == updatedMessage.id }) {
            currentMessages[index] = updatedMessage
            messages = currentMessages
            
            // Notify delegate
            notifyDelegateOfChanges()
        }
    }
    
    private func handleDeletedMessage(_ deletedMessage: ChatMessage) {
        var currentMessages = messages
        
        // Remove the message from the array
        currentMessages.removeAll { $0.id == deletedMessage.id }
        messages = currentMessages
        
        // Notify delegate
        notifyDelegateOfChanges()
    }
    
    private func handleMessageRead(_ readEvent: MessageReadEvent) {
        let updatedChannel = readEvent.channel
        channel = updatedChannel

        if var updatedMessage = messages.first {
            updatedMessage.updateReadBy(with: updatedChannel.reads)
            handleUpdatedMessage(updatedMessage)
        }
    }
    
    private func handleNewReaction(_ reactionEvent: ReactionNewEvent) {
        updateMessage(reactionEvent.message)
    }
    
    private func handleUpdatedReaction(_ reactionEvent: ReactionUpdatedEvent) {
        updateMessage(reactionEvent.message)
    }
    
    private func handleDeletedReaction(_ reactionEvent: ReactionDeletedEvent) {
        updateMessage(reactionEvent.message)
    }
    
    private func updateMessage(
        _ updatedMessage: ChatMessage
    ) {
        let messageId = updatedMessage.id
        var currentMessages = messages
        
        // Find the message to update
        guard let messageIndex = currentMessages.firstIndex(where: { $0.id == messageId }) else {
            return
        }

        // Update the message in the array
        currentMessages[messageIndex] = updatedMessage
        messages = currentMessages
        
        // Notify delegate of changes
        notifyDelegateOfChanges()
    }
    
    private func notifyDelegateOfChanges() {
        guard let currentChannel = channel else { return }
        
        delegate?.livestreamChannelController(self, didUpdateChannel: .update(currentChannel))
        delegate?.livestreamChannelController(self, didUpdateMessages: messages)
    }
}

// MARK: - Delegate Protocol

/// Delegate protocol for `LivestreamChannelController`
public protocol LivestreamChannelControllerDelegate: AnyObject {
    /// Called when the channel data is updated
    /// - Parameters:
    ///   - controller: The controller that updated
    ///   - change: The change that occurred
    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didUpdateChannel change: EntityChange<ChatChannel>
    )
    
    /// Called when the messages are updated
    /// - Parameters:
    ///   - controller: The controller that updated
    ///   - messages: The current messages array
    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didUpdateMessages messages: [ChatMessage]
    )
}

// MARK: - Default Implementations

public extension LivestreamChannelControllerDelegate {
    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didUpdateChannel change: EntityChange<ChatChannel>
    ) {}
    
    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didUpdateMessages messages: [ChatMessage]
    ) {}
}

extension ChatMessage {
    mutating func updateReadBy(
        with reads: [ChatChannelRead]
    ) {
        let createdAtInterval = createdAt.timeIntervalSince1970
        let messageUserId = author.id
        let readBy = reads.filter { read in
            read.user.id != messageUserId && read.lastReadAt.timeIntervalSince1970 >= createdAtInterval
        }
        let newMessage = changing(readBy: Set(readBy.map(\.user)))
        self = newMessage
    }
}
