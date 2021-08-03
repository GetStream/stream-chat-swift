//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
    /// Creates a new `ChatChannelController` for the channel with the provided id.
    ///
    /// - Parameter cid: The id of the channel this controller represents.
    ///
    /// - Returns: A new instance of `ChatChannelController`.
    ///
    func channelController(for cid: ChannelId) -> ChatChannelController {
        .init(channelQuery: .init(cid: cid), client: self)
    }
    
    /// Creates a new `ChatChannelController` for the channel with the provided channel query.
    ///
    /// - Parameter channelQuery: The ChannelQuery this controller represents
    ///
    /// - Returns: A new instance of `ChatChannelController`.
    ///
    func channelController(for channelQuery: ChannelQuery) -> ChatChannelController {
        .init(channelQuery: channelQuery, client: self)
    }
    
    /// Creates a `ChatChannelController` that will create a new channel, if the channel doesn't exist already.
    ///
    /// It's safe to call this method for already existing channels. However, if you queried the channel before and you're sure it exists locally,
    /// it can be faster and more convenient to use `channelController(for cid: ChannelId)` to create a controller for it.
    ///
    /// - Parameters:
    ///   - cid: The `ChannelId` for the new channel.
    ///   - name: The new channel name.
    ///   - imageURL: The new channel avatar URL.
    ///   - team: Team for new channel.
    ///   - members: Ds for the new channel members.
    ///   - isCurrentUserMember: If set to `true` the current user will be included into the channel. Is `true` by default.
    ///   - invites: IDs for the new channel invitees.
    ///   - extraData: Extra data for the new channel.
    /// - Throws: `ClientError.CurrentUserDoesNotExist` if there is no currently logged-in user.
    /// - Returns: A new instance of `ChatChannelController`.
    func channelController(
        createChannelWithId cid: ChannelId,
        name: String? = nil,
        imageURL: URL? = nil,
        team: String? = nil,
        members: Set<UserId> = [],
        isCurrentUserMember: Bool = true,
        invites: Set<UserId> = [],
        extraData: [String: RawJSON] = [:]
    ) throws -> ChatChannelController {
        guard let currentUserId = currentUserId else {
            throw ClientError.CurrentUserDoesNotExist()
        }

        let payload = ChannelEditDetailPayload(
            cid: cid,
            name: name,
            imageURL: imageURL,
            team: team,
            members: members.union(isCurrentUserMember ? [currentUserId] : []),
            invites: invites,
            extraData: extraData
        )

        return .init(channelQuery: .init(channelPayload: payload), client: self, isChannelAlreadyCreated: false)
    }

    /// Creates a `ChatChannelController` that will create a new channel with the provided members without having to specify
    /// the channel id explicitly. This is great for direct message channels because the channel should be uniquely identified by
    /// its members. If the channel for these members already exist, it will be reused.
    ///
    /// It's safe to call this method for already existing channels. However, if you queried the channel before and you're sure it exists locally,
    /// it can be faster and more convenient to use `channelController(for cid: ChannelId)` to create a controller for it.
    ///
    /// - Parameters:
    ///   - members: Members for the new channel. Must not be empty.
    ///   - type: The type of the channel.
    ///   - isCurrentUserMember: If set to `true` the current user will be included into the channel. Is `true` by default.
    ///   - name: The new channel name.
    ///   - imageURL: The new channel avatar URL.
    ///   - team: Team for the new channel.
    ///   - extraData: Extra data for the new channel.
    /// - Throws:
    ///     - `ClientError.ChannelEmptyMembers` if `members` is empty.
    ///     - `ClientError.CurrentUserDoesNotExist` if there is no currently logged-in user.
    /// - Returns: A new instance of `ChatChannelController`.
    func channelController(
        createDirectMessageChannelWith members: Set<UserId>,
        type: ChannelType = .messaging,
        isCurrentUserMember: Bool = true,
        name: String? = nil,
        imageURL: URL? = nil,
        team: String? = nil,
        extraData: [String: RawJSON]
    ) throws -> ChatChannelController {
        guard let currentUserId = currentUserId else { throw ClientError.CurrentUserDoesNotExist() }
        guard !members.isEmpty else { throw ClientError.ChannelEmptyMembers() }

        let payload = ChannelEditDetailPayload(
            type: type,
            name: name,
            imageURL: imageURL,
            team: team,
            members: members.union(isCurrentUserMember ? [currentUserId] : []),
            invites: [],
            extraData: extraData
        )
        return .init(channelQuery: .init(channelPayload: payload), client: self, isChannelAlreadyCreated: false)
    }
}

/// `ChatChannelController` is a controller class which allows mutating and observing changes of a specific chat channel.
///
/// `ChatChannelController` objects are lightweight, and they can be used for both, continuous data change observations (like
/// getting new messages in the channel), and for quick channel mutations (like adding a member to a channel).
///
public class ChatChannelController: DataController, DelegateCallable, DataStoreProvider {
    /// The ChannelQuery this controller observes.
    @Atomic public private(set) var channelQuery: ChannelQuery
    
    /// Flag indicating whether channel is created on backend. We need this flag to restrict channel modification requests
    /// before channel is created on backend.
    /// There are 2 ways of creating new channel:
    /// 1. Direct message channel.
    /// In this case before channel creation `cid` on `channelQuery` will be nil cause it will be generated on backend.
    /// 2. Channels with client generated `id`.
    /// In this case `cid` on `channelQuery `will be valid but all channel modifications will
    /// fail because channel with provided `id` will be missing on backend side.
    /// That is why we need to check both flag and valid `cid` before modifications.
    private var isChannelAlreadyCreated: Bool

    /// A Boolean value that returns wether the previous messages have all been loaded or not.
    public private(set) var hasLoadedAllPreviousMessages: Bool = false

    /// The identifier of a channel this controller observes.
    /// Will be `nil` when we want to create direct message channel and `id`
    /// is not yet generated by backend.
    public var cid: ChannelId? { channelQuery.cid }
    
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient
    
    /// The channel the controller represents.
    ///
    /// To observe changes of the channel, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var channel: ChatChannel? {
        if state == .initialized {
            setLocalStateBasedOnError(startDatabaseObservers())
        }
        return channelObserver?.item
    }
    
    /// The messages of the channel the controller represents.
    ///
    /// To observe changes of the messages, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var messages: LazyCachedMapCollection<ChatMessage> {
        if state == .initialized {
            setLocalStateBasedOnError(startDatabaseObservers())
        }
        return messagesObserver?.items ?? []
    }
    
    /// Describes the ordering the messages are presented.
    ///
    /// - Important: ⚠️ Changing this value doesn't trigger delegate methods. You should reload your UI manually after changing
    /// the `listOrdering` value to reflect the changes. Further updates to the messages will be delivered using the delegate
    /// methods, as usual.
    ///
    public var listOrdering: ListOrdering = .topToBottom {
        didSet {
            if state != .initialized {
                setLocalStateBasedOnError(startMessagesObserver())
                log.warning(
                    "Changing `listOrdering` will update data inside controller, but you have to update your UI manually "
                        + "to see changes."
                )
            }
        }
    }

    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var updater: ChannelUpdater = self.environment.channelUpdaterBuilder(
        client.databaseContainer,
        client.apiClient
    )
    
    private lazy var eventSender: TypingEventsSender = self.environment.eventSenderBuilder(
        client.databaseContainer,
        client.apiClient
    )
    
    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<AnyChannelControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.mainDelegate = multicastDelegate.mainDelegate
            stateMulticastDelegate.additionalDelegates = multicastDelegate.additionalDelegates
            
            // After setting delegate local changes will be fetched and observed.
            setLocalStateBasedOnError(startDatabaseObservers())
        }
    }

    /// Database observers.
    /// Will be `nil` when observing channel with backend generated `id` is not yet created.
    @Cached private var channelObserver: EntityDatabaseObserver<ChatChannel, ChannelDTO>?
    @Cached private var messagesObserver: ListDatabaseObserver<ChatMessage, MessageDTO>?
    
    private var eventObservers: [EventObserver] = []
    private let environment: Environment
    
    /// This callback is called after channel is created on backend but before channel is saved to DB. When channel is created
    /// we receive backend generated cid and setting up current `ChannelController` to observe this channel DB changes.
    /// Completion will be called if DB fetch will fail after setting new `ChannelQuery`.
    private func channelCreated(forwardErrorTo completion: ((_ error: Error?) -> Void)?) -> ((ChannelId) -> Void) {
        return { [weak self] cid in
            guard let self = self else { return }
            self.isChannelAlreadyCreated = true
            completion?(self.set(cid: cid))
        }
    }
    
    /// Helper for updating state after fetching local data.
    private var setLocalStateBasedOnError: ((_ error: Error?) -> Void) {
        return { [weak self] error in
            // Update observing state
            self?.state = error == nil ? .localDataFetched : .localDataFetchFailed(ClientError(with: error))
        }
    }
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    lazy var basePublishers: BasePublishers = .init(controller: self)

    /// Creates a new `ChannelController`
    /// - Parameters:
    ///   - channelQuery: channel query for observing changes
    ///   - client: The `Client` this controller belongs to.
    ///   - environment: Environment for this controller.
    ///   - isChannelAlreadyCreated: Flag indicating whether channel is created on backend.
    init(
        channelQuery: ChannelQuery,
        client: ChatClient,
        environment: Environment = .init(),
        isChannelAlreadyCreated: Bool = true
    ) {
        self.channelQuery = channelQuery
        self.client = client
        self.environment = environment
        self.isChannelAlreadyCreated = isChannelAlreadyCreated
        super.init()

        setChannelObserver()
        setMessagesObserver()
    }

    private func setChannelObserver() {
        _channelObserver.computeValue = { [unowned self] in
            guard let cid = self.cid else { return nil }
            let observer = EntityDatabaseObserver(
                context: self.client.databaseContainer.viewContext,
                fetchRequest: ChannelDTO.fetchRequest(for: cid),
                itemCreator: { $0.asModel() as ChatChannel }
            ).onChange { change in
                self.delegateCallback { $0.channelController(self, didUpdateChannel: change) }
            }
            .onFieldChange(\.currentlyTypingUsers) { change in
                self.delegateCallback {
                    $0.channelController(self, didChangeTypingUsers: change.item)
                }
            }

            return observer
        }
    }

    private func setMessagesObserver() {
        _messagesObserver.computeValue = { [unowned self] in
            guard let cid = self.cid else { return nil }
            let sortAscending = self.listOrdering == .topToBottom ? false : true
            var deletedMessageVisibility: ChatClientConfig.DeletedMessageVisibility?
            self.client.databaseContainer.viewContext.performAndWait {
                deletedMessageVisibility = self.client.databaseContainer.viewContext.deletedMessagesVisibility
            }

            let observer = ListDatabaseObserver(
                context: self.client.databaseContainer.viewContext,
                fetchRequest: MessageDTO.messagesFetchRequest(
                    for: cid,
                    sortAscending: sortAscending,
                    deletedMessagesVisibility: deletedMessageVisibility ?? .visibleForCurrentUser
                ),
                itemCreator: { $0.asModel() as ChatMessage }
            )
            observer.onChange = { changes in
                self.delegateCallback {
                    $0.channelController(self, didUpdateMessages: changes)
                }
            }

            return observer
        }
    }
    
    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        let channelCreatedCallback = isChannelAlreadyCreated ? nil : channelCreated(forwardErrorTo: setLocalStateBasedOnError)
        updater.update(
            channelQuery: channelQuery,
            channelCreatedCallback: channelCreatedCallback
        ) { result in
            self.state = result.error == nil ? .remoteDataFetched : .remoteDataFetchFailed(ClientError(with: result.error))
            self.callback { completion?(result.error) }
        }
        
        /// Setup observers if we know the channel `cid` (if it's missing, it'll be set in `set(cid:)`
        /// Otherwise they will be set up after channel creation, in `set(cid:)`.
        if let cid = cid {
            setupEventObservers(for: cid)
            setLocalStateBasedOnError(startDatabaseObservers())
        }
    }

    /// Sets new cid of the query if necessary, and resets event and database observers.
    ///
    /// This should only be called when the controller is initialized with a new channel
    /// (which doesn't exist on backend), and after that channel is created on backend.
    /// If the newly created channel has a different cid than initially thought
    /// (such is the case for direct messages - backend generates custom cid),
    /// this function will set the new cid and reset observers.
    /// If the cid is not changed, this function will not do anything.
    /// - Parameter cid: New cid for the channel
    /// - Returns: Error if it occurs while setting up database observers.
    private func set(cid: ChannelId) -> Error? {
        guard self.cid != cid else { return nil }
        
        channelQuery = ChannelQuery(cid: cid, channelQuery: channelQuery)
        setupEventObservers(for: cid)
        
        let error = startDatabaseObservers()
        guard error == nil else { return error }
        
        // If there's a channel already in the database, we must
        // simulate the existing data callbacks.
        // Otherwise, the changes will be reported when DB write is completed.
        
        // The reason is, when we don't have the cid, the initial fetches return empty/nil entities
        // and only following updates are reported, hence initial values are ignored.
        guard let channel = channel else { return nil }
        delegateCallback {
            $0.channelController(self, didUpdateChannel: .create(channel))
            $0.channelController(
                self,
                didUpdateMessages: self.messages.enumerated()
                    .map { ListChange.insert($1, index: IndexPath(item: $0, section: 0)) }
            )
        }
        return nil
    }

    private func startDatabaseObservers() -> Error? {
        startChannelObserver() ?? startMessagesObserver()
    }
    
    private func startChannelObserver() -> Error? {
        _channelObserver.reset()
        
        do {
            try channelObserver?.startObserving()
            return nil
        } catch {
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
            return ClientError.FetchFailed()
        }
    }
    
    private func startMessagesObserver() -> Error? {
        _messagesObserver.reset()
        
        do {
            try messagesObserver?.startObserving()
            return nil
        } catch {
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
            return ClientError.FetchFailed()
        }
    }

    private func setupEventObservers(for cid: ChannelId) {
        eventObservers.removeAll()
        // We can't setup event observers in connectionless mode
        guard let webSocketClient = client.webSocketClient else { return }
        let center = webSocketClient.eventNotificationCenter
        eventObservers = [
            MemberEventObserver(notificationCenter: center, cid: cid) { [unowned self] event in
                self.delegateCallback {
                    $0.channelController(self, didReceiveMemberEvent: event)
                }
            }
        ]
    }
    
    /// Sets the provided object as a delegate of this controller.
    ///
    /// - Note: If you don't use custom extra data types, you can set the delegate directly using `controller.delegate = self`.
    /// Due to the current limits of Swift and the way it handles protocols with associated types, it's required to use this
    /// method to set the delegate, if you're using custom extra data types.
    ///
    /// - Parameter delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object
    /// alive if you want keep receiving updates.
    ///
    public func setDelegate<Delegate: ChatChannelControllerDelegate>(_ delegate: Delegate) {
        multicastDelegate.mainDelegate = AnyChannelControllerDelegate(delegate)
    }
}

// MARK: - Channel features

public extension ChatChannelController {
    /// `true` if the channel has typing events enabled. Defaults to `false` if the channel doesn't exist yet.
    var areTypingEventsEnabled: Bool { channel?.config.typingEventsEnabled == true }
    
    /// `true` if the channel has reactions enabled. Defaults to `false` if the channel doesn't exist yet.
    var areReactionsEnabled: Bool { channel?.config.reactionsEnabled == true }
    
    /// `true` if the channel has replies enabled. Defaults to `false` if the channel doesn't exist yet.
    var areRepliesEnabled: Bool { channel?.config.repliesEnabled == true }
    
    /// `true` if the channel has read events enabled. Defaults to `false` if the channel doesn't exist yet.
    var areReadEventsEnabled: Bool { channel?.config.readEventsEnabled == true }
    
    /// `true` if the channel supports uploading files/images. Defaults to `false` if the channel doesn't exist yet.
    var areUploadsEnabled: Bool { channel?.config.uploadsEnabled == true }
}

// MARK: - Channel actions

public extension ChatChannelController {
    /// Updated channel with new data.
    ///
    /// - Parameters:
    ///   - team: New team.
    ///   - members: New members.
    ///   - invites: New invites.
    ///   - extraData: New `ExtraData`.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    func updateChannel(
        name: String?,
        imageURL: URL?,
        team: String?,
        members: Set<UserId> = [],
        invites: Set<UserId> = [],
        extraData: [String: RawJSON] = [:],
        completion: ((Error?) -> Void)? = nil
    ) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }

        let payload: ChannelEditDetailPayload = .init(
            cid: cid,
            name: name,
            imageURL: imageURL,
            team: team,
            members: members,
            invites: invites,
            extraData: extraData
        )
        
        updater.updateChannel(channelPayload: payload) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Mutes the channel this controller manages.
    ///
    /// - Parameter completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                         If request fails, the completion will be called with an error.
    ///
    func muteChannel(completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        
        updater.muteChannel(cid: cid, mute: true) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Unmutes the channel this controller manages.
    ///
    /// - Parameters:
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    func unmuteChannel(completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        
        updater.muteChannel(cid: cid, mute: false) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Delete the channel this controller manages.
    /// - Parameters:
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    func deleteChannel(completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        
        updater.deleteChannel(cid: cid) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Truncates the channel this controller manages.
    ///
    /// Removes all of the messages of the channel but doesn't affect the channel data or members.
    ///
    /// - Parameter completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    /// If request fails, the completion will be called with an error.
    ///
    func truncateChannel(completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }

        updater.truncateChannel(cid: cid) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Hide the channel this controller manages from queryChannels for the user until a message is added.
    ///
    /// - Parameters:
    ///   - clearHistory: Flag to remove channel history (**false** by default)
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    func hideChannel(clearHistory: Bool = false, completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        
        updater.hideChannel(cid: cid, clearHistory: clearHistory) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Removes hidden status for the channel this controller manages.
    ///
    /// - Parameter completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                         If request fails, the completion will be called with an error.
    ///
    func showChannel(completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        
        updater.showChannel(cid: cid) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Loads previous messages from backend.
    ///
    /// - Parameters:
    ///   - messageId: ID of the last fetched message. You will get messages `older` than the provided ID.
    ///   - limit: Limit for page size.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    func loadPreviousMessages(
        before messageId: MessageId? = nil,
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard cid != nil, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        
        guard let messageId = messageId ?? messages.last?.id else {
            log.error(ClientError.ChannelEmptyMessages().localizedDescription)
            callback { completion?(ClientError.ChannelEmptyMessages()) }
            return
        }

        guard !hasLoadedAllPreviousMessages else {
            completion?(nil)
            return
        }
        
        channelQuery.pagination = MessagesPagination(pageSize: limit, parameter: .lessThan(messageId))
    
        updater.update(channelQuery: channelQuery, completion: { result in
            switch result {
            case let .success(payload):
                self.hasLoadedAllPreviousMessages = payload.messages.count < limit
                self.callback { completion?(nil) }
            case let .failure(error):
                self.callback { completion?(error) }
            }
        })
    }
    
    /// Loads next messages from backend.
    ///
    /// - Parameters:
    ///   - messageId: ID of the current first message. You will get messages `newer` than the provided ID.
    ///   - limit: Limit for page size.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    func loadNextMessages(
        after messageId: MessageId? = nil,
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard cid != nil, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        
        guard let messageId = messageId ?? messages.first?.id else {
            log.error(ClientError.ChannelEmptyMessages().localizedDescription)
            callback { completion?(ClientError.ChannelEmptyMessages()) }
            return
        }
        
        channelQuery.pagination = MessagesPagination(pageSize: limit, parameter: .greaterThan(messageId))
        
        updater.update(channelQuery: channelQuery, completion: { result in
            self.callback { completion?(result.error) }
        })
    }
     
    /// Sends the start typing event and schedule a timer to send the stop typing event.
    ///
    /// This method is meant to be called every time the user presses a key. The method will manage requests and timer as needed.
    ///
    /// - Parameter completion: a completion block with an error if the request was failed.
    ///
    func sendKeystrokeEvent(completion: ((Error?) -> Void)? = nil) {
        /// Ignore if typing events are not enabled
        guard areTypingEventsEnabled else {
            callback {
                completion?(nil)
            }
            return
        }

        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed { completion?($0) }
            return
        }
        
        eventSender.keystroke(in: cid, completion: completion)
    }
    
    /// Sends the start typing event.
    ///
    /// For the majority of cases, you don't need to call `sendStartTypingEvent` directly. Instead, use `sendKeystrokeEvent`
    /// method and call it every time the user presses a key. The controller will manage
    /// `sendStartTypingEvent`/`sendStopTypingEvent` calls automatically.
    ///
    /// - Parameter completion: a completion block with an error if the request was failed.
    ///
    func sendStartTypingEvent(completion: ((Error?) -> Void)? = nil) {
        /// Ignore if typing events are not enabled
        guard areTypingEventsEnabled else {
            channelFeatureDisabled(feature: "typing events", completion: completion)
            return
        }

        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed { completion?($0) }
            return
        }
        
        eventSender.startTyping(in: cid, completion: completion)
    }
    
    /// Sends the stop typing event.
    ///
    /// For the majority of cases, you don't need to call `sendStopTypingEvent` directly. Instead, use `sendKeystrokeEvent`
    /// method and call it every time the user presses a key. The controller will manage
    /// `sendStartTypingEvent`/`sendStopTypingEvent` calls automatically.
    ///
    /// - Parameter completion: a completion block with an error if the request was failed.
    ///
    func sendStopTypingEvent(completion: ((Error?) -> Void)? = nil) {
        /// Ignore if typing events are not enabled
        guard areTypingEventsEnabled else {
            channelFeatureDisabled(feature: "typing events", completion: completion)
            return
        }

        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed { completion?($0) }
            return
        }
        
        eventSender.stopTyping(in: cid, completion: completion)
    }
    
    /// Creates a new message locally and schedules it for send.
    ///
    /// - Parameters:
    ///   - text: Text of the message.
    ///   - pinning: Pins the new message. `nil` if should not be pinned.
    ///   - isSilent: A flag indicating whether the message is a silent message. Silent messages are special messages that don't increase the unread messages count nor mark a channel as unread.
    ///   - attachments: An array of the attachments for the message.
    ///     `Note`: can be built-in types, custom attachment types conforming to `AttachmentEnvelope` protocol
    ///     and `ChatMessageAttachmentSeed`s.
    ///   - quotedMessageId: An id of the message new message quotes. (inline reply)
    ///   - extraData: Additional extra data of the message object.
    ///   - completion: Called when saving the message to the local DB finishes.
    ///
    func createNewMessage(
        text: String,
        pinning: MessagePinning? = nil,
//        command: String? = nil,
//        arguments: String? = nil,
        isSilent: Bool = false,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        quotedMessageId: MessageId? = nil,
        extraData: [String: RawJSON] = [:],
        completion: ((Result<MessageId, Error>) -> Void)? = nil
    ) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed { error in
                completion?(.failure(error ?? ClientError.Unknown()))
            }
            return
        }
        
        /// Send stop typing event.
        eventSender.stopTyping(in: cid)
        
        updater.createNewMessage(
            in: cid,
            text: text,
            pinning: pinning,
            isSilent: isSilent,
            command: nil,
            arguments: nil,
            attachments: attachments,
            mentionedUserIds: mentionedUserIds,
            quotedMessageId: quotedMessageId,
            extraData: extraData
        ) { result in
            self.callback {
                completion?(result)
            }
        }
    }

    /// A convenience method that invokes the completion? with a ChannelFeatureDisabled error
    /// ie. VCs should use the `are{FEATURE_NAME}Enabled` props (ie. `areReadEventsEnabled`) before using any feature
    private func channelFeatureDisabled(feature: String, completion: ((Error?) -> Void)?) {
        let error = ClientError.ChannelFeatureDisabled("Channel feature: \(feature) is disabled for this channel.")
        log.error(error.localizedDescription)
        callback {
            completion?(error)
        }
    }

    // It's impossible to perform any channel modification before it's creation on backend.
    // So before any modification attempt we need to check if channel is already created and call this function if not.
    private func channelModificationFailed(_ completion: ((Error?) -> Void)?) {
        let error = ClientError.ChannelNotCreatedYet()
        log.error(error.localizedDescription)
        callback {
            completion?(error)
        }
    }
    
    /// Add users to the channel as members.
    ///
    /// - Parameters:
    ///   - users: Users Id to add to a channel.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    func addMembers(userIds: Set<UserId>, completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        
        updater.addMembers(cid: cid, userIds: userIds) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Remove users to the channel as members.
    ///
    /// - Parameters:
    ///   - users: Users Id to add to a channel.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    func removeMembers(userIds: Set<UserId>, completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        
        updater.removeMembers(cid: cid, userIds: userIds) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Invite members to a channel. They can then accept or decline the invitation
    /// - Parameters:
    ///   - userIds: Set of ids of users to be invited to the channel
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func inviteMembers(userIds: Set<UserId>, completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        
        updater.inviteMembers(cid: cid, userIds: userIds) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Accept Request
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - userId: userId
    ///   - message: message
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func acceptInvite(message: String? = nil, completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        updater.acceptInvite(cid: cid, message: message) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Reject Request
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func rejectInvite(completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        
        updater.rejectInvite(cid: cid) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Marks the channel as read.
    ///
    /// - Parameter completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                         If request fails, the completion will be called with an error.
    ///
    func markRead(completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }

        /// Read events are not enabled for this channel
        guard areReadEventsEnabled else {
            channelFeatureDisabled(feature: "read events", completion: completion)
            return
        }
        
        if channel?.isUnread != true {
            callback {
                completion?(nil)
            }
            return
        }

        updater.markRead(cid: cid) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Enables slow mode for the channel
    ///
    /// When slow mode is enabled, users can only send a message every `cooldownDuration` time interval.
    /// `cooldownDuration` is specified in seconds, and should be between 1-120.
    /// For more information, please check [documentation](https://getstream.io/chat/docs/javascript/slow_mode/?language=swift).
    ///
    /// - Parameters:
    ///   - cooldownDuration: Duration of the time interval users have to wait between messages.
    ///   Specified in seconds. Should be between 1-120.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func enableSlowMode(cooldownDuration: Int, completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        guard cooldownDuration >= 1, cooldownDuration <= 120 else {
            callback {
                completion?(ClientError.InvalidCooldownDuration())
            }
            return
        }
        updater.enableSlowMode(cid: cid, cooldownDuration: cooldownDuration) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Disables slow mode for the channel
    ///
    /// For more information, please check [documentation](https://getstream.io/chat/docs/javascript/slow_mode/?language=swift).
    ///
    /// - Parameters:
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func disableSlowMode(completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        updater.enableSlowMode(cid: cid, cooldownDuration: 0) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Start watching a channel
    ///
    /// Watching a channel is defined as observing notifications about this channel.
    /// Usually you don't need to call this function since `ChannelController` watches channels
    /// by default.
    ///
    /// Please check [documentation](https://getstream.io/chat/docs/android/watch_channel/?language=swift) for more information.
    ///
    /// We keep these functions internal since we're not sure how we should interface this behavior.
    /// If you have suggestions, please open a ticket or send us an email at support@getstream.io
    ///
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    internal func startWatching(completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        updater.startWatching(cid: cid) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Stop watching a channel
    ///
    /// Watching a channel is defined as observing notifications about this channel.
    /// `ChannelController` watches the channel by default so if you want to create a `ChannelController`
    ///  without watching the channel, either you can create it and call this function, or you can create it as:
    /// ```
    /// var query = ChannelQuery(cid: cid)
    /// query.options = [] // by default, we pass `.watch` option here
    /// let controller = client.channelController(for: query)
    /// ```
    ///
    /// Please check [documentation](https://getstream.io/chat/docs/android/watch_channel/?language=swift) for more information.
    ///
    /// We keep these functions internal since we're not sure how we should interface this behavior.
    /// If you have suggestions, please open a ticket or send us an email at support@getstream.io
    ///
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    internal func stopWatching(completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        updater.stopWatching(cid: cid) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Freezes the channel.
    ///
    /// Freezing a channel will disallow sending new messages and sending / deleting reactions.
    /// For more information, see https://getstream.io/chat/docs/ios-swift/freezing_channels/?language=swift
    ///
    /// - Parameter completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    func freezeChannel(completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        
        updater.freezeChannel(true, cid: cid) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Unfreezes the channel.
    ///
    /// Freezing a channel will disallow sending new messages and sending / deleting reactions.
    /// For more information, see https://getstream.io/chat/docs/ios-swift/freezing_channels/?language=swift
    ///
    /// - Parameter completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    func unfreezeChannel(completion: ((Error?) -> Void)? = nil) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }
        
        updater.freezeChannel(false, cid: cid) { error in
            self.callback {
                completion?(error)
            }
        }
    }
}

extension ChatChannelController {
    struct Environment {
        var channelUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelUpdater = ChannelUpdater.init
        
        var eventSenderBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> TypingEventsSender = TypingEventsSender.init
    }
}

public extension ChatChannelController {
    /// Set the delegate of `ChannelController` to observe the changes in the system.
    ///
    /// - Note: The delegate can be set directly only if you're **not** using custom extra data types. Due to the current
    /// limits of Swift and the way it handles protocols with associated types, it's required to use `setDelegate` method
    /// instead to set the delegate, if you're using custom extra data types.
    var delegate: ChatChannelControllerDelegate? {
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? ChatChannelControllerDelegate }
        set { multicastDelegate.mainDelegate = AnyChannelControllerDelegate(newValue) }
    }
}

/// Describes the flow of the items in the list
public enum ListOrdering {
    /// New items appear on the top of the list.
    case topToBottom
    
    /// New items appear on the bottom of the list.
    case bottomToTop
}

// MARK: - Delegates

/// `ChatChannelController` uses this protocol to communicate changes to its delegate.
///
/// If you're **not** using custom extra data types, you can use a convenience version of this protocol
/// named `ChatChannelControllerDelegate`, which hides the generic types, and make the usage easier.
///
public protocol ChatChannelControllerDelegate: DataControllerStateDelegate {
    /// The controller observed a change in the `Channel` entity.
    func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    )
    
    /// The controller observed changes in the `Messages` of the observed channel.
    func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    )

    /// The controller received a `MemberEvent` related to the channel it observes.
    func channelController(_ channelController: ChatChannelController, didReceiveMemberEvent: MemberEvent)
    
    /// The controller received a change related to users typing in the channel it observes.
    func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    )
}

public extension ChatChannelControllerDelegate {
    func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) {}
    
    func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {}

    func channelController(_ channelController: ChatChannelController, didReceiveMemberEvent: MemberEvent) {}
    
    func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers: Set<ChatUser>
    ) {}
}

// MARK: Type erased Delegate

class AnyChannelControllerDelegate: ChatChannelControllerDelegate {
    private var _controllerdidUpdateMessages: (
        ChatChannelController,
        [ListChange<ChatMessage>]
    ) -> Void
    
    private var _controllerDidUpdateChannel: (
        ChatChannelController,
        EntityChange<ChatChannel>
    ) -> Void

    private var _controllerDidChangeState: (DataController, DataController.State) -> Void
    
    private var _controllerDidReceiveMemberEvent: (
        ChatChannelController,
        MemberEvent
    ) -> Void
    
    private var _controllerDidChangeTypingUsers: (
        ChatChannelController,
        Set<ChatUser>
    ) -> Void

    weak var wrappedDelegate: AnyObject?
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (DataController, DataController.State) -> Void,
        controllerDidUpdateChannel: @escaping (
            ChatChannelController,
            EntityChange<ChatChannel>
        ) -> Void,
        controllerdidUpdateMessages: @escaping (
            ChatChannelController,
            [ListChange<ChatMessage>]
        ) -> Void,
        controllerDidReceiveMemberEvent: @escaping (
            ChatChannelController,
            MemberEvent
        ) -> Void,
        controllerDidChangeTypingUsers: @escaping (
            ChatChannelController,
            Set<ChatUser>
        ) -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeState = controllerDidChangeState
        _controllerDidUpdateChannel = controllerDidUpdateChannel
        _controllerdidUpdateMessages = controllerdidUpdateMessages
        _controllerDidReceiveMemberEvent = controllerDidReceiveMemberEvent
        _controllerDidChangeTypingUsers = controllerDidChangeTypingUsers
    }
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        _controllerDidChangeState(controller, state)
    }
    
    func channelController(
        _ controller: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) {
        _controllerDidUpdateChannel(controller, channel)
    }
    
    func channelController(
        _ controller: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {
        _controllerdidUpdateMessages(controller, changes)
    }
    
    func channelController(
        _ controller: ChatChannelController,
        didReceiveMemberEvent event: MemberEvent
    ) {
        _controllerDidReceiveMemberEvent(controller, event)
    }
    
    func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    ) {
        _controllerDidChangeTypingUsers(channelController, typingUsers)
    }
}

extension AnyChannelControllerDelegate {
    convenience init<Delegate: ChatChannelControllerDelegate>(_ delegate: Delegate) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidUpdateChannel: { [weak delegate] in delegate?.channelController($0, didUpdateChannel: $1) },
            controllerdidUpdateMessages: { [weak delegate] in delegate?.channelController($0, didUpdateMessages: $1) },
            controllerDidReceiveMemberEvent: { [weak delegate] in
                delegate?.channelController($0, didReceiveMemberEvent: $1)
            },
            controllerDidChangeTypingUsers: { [weak delegate] in
                delegate?.channelController($0, didChangeTypingUsers: $1)
            }
        )
    }
}

extension AnyChannelControllerDelegate {
    convenience init(_ delegate: ChatChannelControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidUpdateChannel: { [weak delegate] in delegate?.channelController($0, didUpdateChannel: $1) },
            controllerdidUpdateMessages: { [weak delegate] in delegate?.channelController($0, didUpdateMessages: $1) },
            controllerDidReceiveMemberEvent: { [weak delegate] in
                delegate?.channelController($0, didReceiveMemberEvent: $1)
            },
            controllerDidChangeTypingUsers: { [weak delegate] in
                delegate?.channelController($0, didChangeTypingUsers: $1)
            }
        )
    }
}

extension ClientError {
    class ChannelNotCreatedYet: ClientError {
        override public var localizedDescription: String {
            "You can't modify the channel because the channel hasn't been created yet. Call `synchronize()` to create the channel and wait for the completion block to finish. Alternatively, you can observe the `state` changes of the controller and wait for the `remoteDataFetched` state."
        }
    }

    class ChannelEmptyMembers: ClientError {
        override public var localizedDescription: String {
            "You can't create direct messaging channel with empty members."
        }
    }
    
    class ChannelEmptyMessages: ClientError {
        override public var localizedDescription: String {
            "You can't load new messages when there is no messages in the channel."
        }
    }
    
    class InvalidCooldownDuration: ClientError {
        override public var localizedDescription: String {
            "You can't specify a value outside the range 1-120 for cooldown duration."
        }
    }
}

extension ClientError {
    class ChannelFeatureDisabled: ClientError {}
}
