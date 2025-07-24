//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public extension ChatClient {
    /// Creates a new `LivestreamChannelController` for the given channel query.
    /// - Parameter channelQuery: The query to observe the channel.
    /// - Returns: A new `LivestreamChannelController` instance.
    func livestreamChannelController(for channelQuery: ChannelQuery) -> LivestreamChannelController {
        LivestreamChannelController(channelQuery: channelQuery, client: self)
    }
}

/// A controller for managing livestream channels that operates without local database persistence.
///
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
    
    /// Current user ID for convenience
    private var currentUserId: UserId? { client.currentUserId }
    
    // MARK: - Initialization
    
    /// Creates a new `LivestreamChannelController`
    /// - Parameters:
    ///   - channelQuery: channel query for observing changes
    ///   - client: The `Client` this controller belongs to.
    init(
        channelQuery: ChannelQuery,
        client: ChatClient
    ) {
        self.channelQuery = channelQuery
        self.client = client
        apiClient = client.apiClient
        paginationStateHandler = MessagesPaginationStateHandler()
        eventsController = client.eventsController()
        eventsController.delegate = self

        if let cid = channelQuery.cid {
            client.eventNotificationCenter.registerManualEventHandling(for: cid)
        }
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
        guard cid != nil else {
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
        guard cid != nil else {
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

        let endpoint: Endpoint<ChannelPayload> =
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
        if let pagination = channelQuery.pagination {
            paginationStateHandler.end(pagination: pagination, with: .success(payload.messages))
        }

        let newChannel = payload.asModel(
            currentUserId: currentUserId,
            currentlyTypingUsers: channel?.currentlyTypingUsers,
            unreadCount: channel?.unreadCount
        )

        let oldChannel = channel
        channel = newChannel

        let newMessages = payload.messages.compactMap {
            $0.asModel(cid: payload.channel.cid, currentUserId: currentUserId, channelReads: newChannel.reads)
        }

        updateMessagesArray(with: newMessages, pagination: channelQuery.pagination)

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
            messages = newMessages
        }
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
            break
        }
    }
    
    private func handleNewMessage(_ message: ChatMessage) {
        // Add new message to the beginning of the array (newest first)
        var currentMessages = messages

        // If message already exists, update it instead
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

        if let index = currentMessages.firstIndex(where: { $0.id == updatedMessage.id }) {
            currentMessages[index] = updatedMessage
            messages = currentMessages

            notifyDelegateOfChanges()
        }
    }
    
    private func handleDeletedMessage(_ deletedMessage: ChatMessage) {
        var currentMessages = messages

        currentMessages.removeAll { $0.id == deletedMessage.id }
        messages = currentMessages

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

        guard let messageIndex = currentMessages.firstIndex(where: { $0.id == messageId }) else {
            return
        }

        currentMessages[messageIndex] = updatedMessage
        messages = currentMessages

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

private extension ChatMessage {
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
