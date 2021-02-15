//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension _ChatClient {
    /// Creates a new `ChatChannelController` for the channel with the provided id and options.
    ///
    /// - Parameter channelId: The id of the channel this controller represents.
    /// - Parameter options: Query options (See `QueryOptions`)
    ///
    /// - Returns: A new instance of `ChatChannelController`.
    ///
    func channelController(for cid: ChannelId) -> _ChatChannelController<ExtraData> {
        .init(channelQuery: .init(cid: cid), client: self)
    }
    
    /// Creates a new `ChatChannelController` for the channel with the provided channel query.
    ///
    /// - Parameter channelQuery: The ChannelQuery this controller represents
    ///
    /// - Returns: A new instance of `ChatChannelController`.
    ///
    func channelController(for channelQuery: _ChannelQuery<ExtraData>) -> _ChatChannelController<ExtraData> {
        .init(channelQuery: channelQuery, client: self)
    }
    
    /// Creates a new `ChatChannelController` that will create a new channel.
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
        name: String?,
        imageURL: URL?,
        team: String? = nil,
        members: Set<UserId> = [],
        isCurrentUserMember: Bool = true,
        invites: Set<UserId> = [],
        extraData: ExtraData.Channel
    ) throws -> _ChatChannelController<ExtraData> {
        guard let currentUserId = currentUserId else {
            throw ClientError.CurrentUserDoesNotExist()
        }

        let payload = ChannelEditDetailPayload<ExtraData>(
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

    /// Creates a new `ChatChannelController` that will create new a channel with provided members without having to specify
    /// the channel id explicitly.
    ///
    /// This is great for direct message channels because the channel should be uniquely identified by its members.
    ///
    /// - Parameters:
    ///   - members: Members for the new channel. Must not be empty.
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
        isCurrentUserMember: Bool = true,
        name: String?,
        imageURL: URL?,
        team: String? = nil,
        extraData: ExtraData.Channel
    ) throws -> _ChatChannelController<ExtraData> {
        guard let currentUserId = currentUserId else { throw ClientError.CurrentUserDoesNotExist() }
        guard !members.isEmpty else { throw ClientError.ChannelEmptyMembers() }

        let payload = ChannelEditDetailPayload<ExtraData>(
            type: .messaging,
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
/// Learn more about `ChatChannelController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#channel).
///
/// - Note: `ChatChannelController` is a typealias of `_ChatChannelController` with default extra data. If you're using custom
/// extra data, create your own typealias of `_ChatChannelController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChatChannelController = _ChatChannelController<NoExtraData>

/// `ChatChannelController` is a controller class which allows mutating and observing changes of a specific chat channel.
///
/// `ChatChannelController` objects are lightweight, and they can be used for both, continuous data change observations (like
/// getting new messages in the channel), and for quick channel mutations (like adding a member to a channel).
///
/// Learn more about `ChatChannelController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#channel).
///
/// - Note: `_ChatChannelController` type is not meant to be used directly. If you're using default extra data, use
/// `ChatChannelController` typealias instead. If you're using custom extra data, create your own typealias
/// of `_ChatChannelController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public class _ChatChannelController<ExtraData: ExtraDataTypes>: DataController, DelegateCallable, DataStoreProvider {
    /// The ChannelQuery this controller observes.
    @Atomic public private(set) var channelQuery: _ChannelQuery<ExtraData>
    
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

    /// The identifier of a channel this controller observes.
    /// Will be `nil` when we want to create direct message channel and `id`
    /// is not yet generated by backend.
    public var cid: ChannelId? { channelQuery.cid }
    
    /// The `ChatClient` instance this controller belongs to.
    public let client: _ChatClient<ExtraData>
    
    /// The channel the controller represents.
    ///
    /// To observe changes of the channel, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var channel: _ChatChannel<ExtraData>? {
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
    public var messages: LazyCachedMapCollection<_ChatMessage<ExtraData>> {
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
    private lazy var updater: ChannelUpdater<ExtraData> = self.environment.channelUpdaterBuilder(
        client.databaseContainer,
        client.apiClient
    )
    
    private lazy var eventSender: EventSender<ExtraData> = self.environment.eventSenderBuilder(
        client.databaseContainer,
        client.apiClient
    )
    
    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<AnyChannelControllerDelegate<ExtraData>> = .init() {
        didSet {
            stateMulticastDelegate.mainDelegate = multicastDelegate.mainDelegate
            stateMulticastDelegate.additionalDelegates = multicastDelegate.additionalDelegates
            
            // After setting delegate local changes will be fetched and observed.
            setLocalStateBasedOnError(startDatabaseObservers())
        }
    }

    /// Database observers.
    /// Will be `nil` when observing channel with backend generated `id` is not yet created.
    @Cached private var channelObserver: EntityDatabaseObserver<_ChatChannel<ExtraData>, ChannelDTO>?
    @Cached private var messagesObserver: ListDatabaseObserver<_ChatMessage<ExtraData>, MessageDTO>?
    
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
        channelQuery: _ChannelQuery<ExtraData>,
        client: _ChatClient<ExtraData>,
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
                itemCreator: { $0.asModel() as _ChatChannel<ExtraData> }
            ).onChange { change in
                self.delegateCallback { $0.channelController(self, didUpdateChannel: change) }
            }
            .onFieldChange(\.currentlyTypingMembers) { change in
                self.delegateCallback {
                    $0.channelController(self, didChangeTypingMembers: change.item)
                }
            }

            return observer
        }
    }

    private func setMessagesObserver() {
        _messagesObserver.computeValue = { [unowned self] in
            guard let cid = self.cid else { return nil }
            let sortAscending = self.listOrdering == .topToBottom ? false : true
            let observer = ListDatabaseObserver(
                context: self.client.databaseContainer.viewContext,
                fetchRequest: MessageDTO.messagesFetchRequest(for: cid, sortAscending: sortAscending),
                itemCreator: { $0.asModel() as _ChatMessage<ExtraData> }
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
        ) { error in
            self.state = error == nil ? .remoteDataFetched : .remoteDataFetchFailed(ClientError(with: error))
            self.callback { completion?(error) }
        }
        
        /// Setup event observers if channel is already created on backend side and have a valid `cid`.
        /// Otherwise they will be set up after channel creation.
        if let cid = cid, isChannelAlreadyCreated {
            setupEventObservers(for: cid)
        }
    }

    /// Sets new cid of the query if necessary, and resets event and database observers.
    ///
    /// This should only be called when the controller is initialized with a new channel
    /// (which doesn't exist on backend), and after that channel is created on backend.
    /// If the newly created channel has a different cid than initially thought
    /// (such is the case for direct messages - backend generates custom cid),
    /// this function will set the new cid and reset observers.
    /// If the cid is still the same, this function will only reset the observers
    /// - since we don't need to set a new query in that case.
    /// - Parameter cid: New cid for the channel
    /// - Returns: Error if it occurs while setting up database observers.
    private func set(cid: ChannelId) -> Error? {
        if channelQuery.cid != cid {
            channelQuery = _ChannelQuery(cid: cid, channelQuery: channelQuery)
        }
        setupEventObservers(for: cid)
        return startDatabaseObservers()
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
    public func setDelegate<Delegate: _ChatChannelControllerDelegate>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData {
        multicastDelegate.mainDelegate = AnyChannelControllerDelegate(delegate)
    }
}

// MARK: - Channel actions

public extension _ChatChannelController {
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
        extraData: ExtraData.Channel,
        completion: ((Error?) -> Void)? = nil
    ) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid, isChannelAlreadyCreated else {
            channelModificationFailed(completion)
            return
        }

        let payload: ChannelEditDetailPayload<ExtraData> = .init(
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
        
        channelQuery.pagination = MessagesPagination(pageSize: limit, parameter: .lessThan(messageId))
    
        updater.update(channelQuery: channelQuery, completion: { error in
            self.callback { completion?(error) }
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
        
        updater.update(channelQuery: channelQuery, completion: { error in
            self.callback { completion?(error) }
        })
    }
    
    /// Sends the start typing event and schedule a timer to send the stop typing event.
    ///
    /// This method is meant to be called every time the user presses a key. The method will manage requests and timer as needed.
    ///
    /// - Parameter completion: a completion block with an error if the request was failed.
    ///
    func sendKeystrokeEvent(completion: ((Error?) -> Void)? = nil) {
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
    ///   - extraData: Additional extra data of the message object.
    ///   - attachments: An array of the attachments for the message.
    ///     `Note`: can be built-in types, custom attachment types conforming to `AttachmentEnvelope` protocol
    ///     and `ChatMessageAttachmentSeed`s.
    ///   - quotedMessageId: An id of the message new message quotes. (inline reply)
    ///   - completion: Called when saving the message to the local DB finishes.
    ///
    func createNewMessage(
        text: String,
//        command: String? = nil,
//        arguments: String? = nil,
        attachments: [AttachmentEnvelope] = [],
        quotedMessageId: MessageId? = nil,
        extraData: ExtraData.Message = .defaultValue,
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
            command: nil,
            arguments: nil,
            attachments: attachments,
            quotedMessageId: quotedMessageId,
            extraData: extraData
        ) { result in
            self.callback {
                completion?(result)
            }
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
        updater.markRead(cid: cid) { error in
            self.callback {
                completion?(error)
            }
        }
    }
}

extension _ChatChannelController {
    struct Environment {
        var channelUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelUpdater<ExtraData> = ChannelUpdater.init
        
        var eventSenderBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> EventSender<ExtraData> = EventSender.init
    }
}

public extension _ChatChannelController where ExtraData == NoExtraData {
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
/// This protocol can be used only when no custom extra data are specified. If you're using custom extra data types,
/// please use `_ChatChannelControllerDelegate` instead.
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
    
    /// The controller received a change related to members typing in the channel it observes.
    func channelController(_ channelController: ChatChannelController, didChangeTypingMembers typingMembers: Set<ChatChannelMember>)
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
        didChangeTypingMembers typingMembers: Set<ChatChannelMember>
    ) {}
}

// MARK: Generic Delegates

/// `ChatChannelController` uses this protocol to communicate changes to its delegate.
///
/// If you're **not** using custom extra data types, you can use a convenience version of this protocol
/// named `ChatChannelControllerDelegate`, which hides the generic types, and make the usage easier.
///
public protocol _ChatChannelControllerDelegate: DataControllerStateDelegate {
    associatedtype ExtraData: ExtraDataTypes
    
    /// The controller observed a change in the `Channel` entity.
    func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    )
    
    /// The controller observed changes in the `Messages` of the observed channel.
    func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    )

    /// The controller received a `MemberEvent` related to the channel it observes.
    func channelController(_ channelController: _ChatChannelController<ExtraData>, didReceiveMemberEvent: MemberEvent)
    
    /// The controller received a change related to members typing in the channel it observes.
    func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didChangeTypingMembers typingMembers: Set<_ChatChannelMember<ExtraData.User>>
    )
}

public extension _ChatChannelControllerDelegate {
    func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) {}
    
    func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {}

    func channelController(_ channelController: _ChatChannelController<ExtraData>, didReceiveMemberEvent: MemberEvent) {}
    
    func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didChangeTypingMembers: Set<_ChatChannelMember<ExtraData.User>>
    ) {}
}

// MARK: Type erased Delegate

class AnyChannelControllerDelegate<ExtraData: ExtraDataTypes>: _ChatChannelControllerDelegate {
    private var _controllerdidUpdateMessages: (
        _ChatChannelController<ExtraData>,
        [ListChange<_ChatMessage<ExtraData>>]
    ) -> Void
    
    private var _controllerDidUpdateChannel: (
        _ChatChannelController<ExtraData>,
        EntityChange<_ChatChannel<ExtraData>>
    ) -> Void

    private var _controllerDidChangeState: (DataController, DataController.State) -> Void
    
    private var _controllerDidReceiveMemberEvent: (
        _ChatChannelController<ExtraData>,
        MemberEvent
    ) -> Void
    
    private var _controllerDidChangeTypingMembers: (
        _ChatChannelController<ExtraData>,
        Set<_ChatChannelMember<ExtraData.User>>
    ) -> Void

    weak var wrappedDelegate: AnyObject?
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (DataController, DataController.State) -> Void,
        controllerDidUpdateChannel: @escaping (
            _ChatChannelController<ExtraData>,
            EntityChange<_ChatChannel<ExtraData>>
        ) -> Void,
        controllerdidUpdateMessages: @escaping (
            _ChatChannelController<ExtraData>,
            [ListChange<_ChatMessage<ExtraData>>]
        ) -> Void,
        controllerDidReceiveMemberEvent: @escaping (
            _ChatChannelController<ExtraData>,
            MemberEvent
        ) -> Void,
        controllerDidChangeTypingMembers: @escaping (
            _ChatChannelController<ExtraData>,
            Set<_ChatChannelMember<ExtraData.User>>
        ) -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeState = controllerDidChangeState
        _controllerDidUpdateChannel = controllerDidUpdateChannel
        _controllerdidUpdateMessages = controllerdidUpdateMessages
        _controllerDidReceiveMemberEvent = controllerDidReceiveMemberEvent
        _controllerDidChangeTypingMembers = controllerDidChangeTypingMembers
    }
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        _controllerDidChangeState(controller, state)
    }
    
    func channelController(
        _ controller: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) {
        _controllerDidUpdateChannel(controller, channel)
    }
    
    func channelController(
        _ controller: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        _controllerdidUpdateMessages(controller, changes)
    }
    
    func channelController(
        _ controller: _ChatChannelController<ExtraData>,
        didReceiveMemberEvent event: MemberEvent
    ) {
        _controllerDidReceiveMemberEvent(controller, event)
    }
    
    func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didChangeTypingMembers typingMembers: Set<_ChatChannelMember<ExtraData.User>>
    ) {
        _controllerDidChangeTypingMembers(channelController, typingMembers)
    }
}

extension AnyChannelControllerDelegate {
    convenience init<Delegate: _ChatChannelControllerDelegate>(_ delegate: Delegate) where Delegate.ExtraData == ExtraData {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidUpdateChannel: { [weak delegate] in delegate?.channelController($0, didUpdateChannel: $1) },
            controllerdidUpdateMessages: { [weak delegate] in delegate?.channelController($0, didUpdateMessages: $1) },
            controllerDidReceiveMemberEvent: { [weak delegate] in
                delegate?.channelController($0, didReceiveMemberEvent: $1)
            },
            controllerDidChangeTypingMembers: { [weak delegate] in
                delegate?.channelController($0, didChangeTypingMembers: $1)
            }
        )
    }
}

extension AnyChannelControllerDelegate where ExtraData == NoExtraData {
    convenience init(_ delegate: ChatChannelControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidUpdateChannel: { [weak delegate] in delegate?.channelController($0, didUpdateChannel: $1) },
            controllerdidUpdateMessages: { [weak delegate] in delegate?.channelController($0, didUpdateMessages: $1) },
            controllerDidReceiveMemberEvent: { [weak delegate] in
                delegate?.channelController($0, didReceiveMemberEvent: $1)
            },
            controllerDidChangeTypingMembers: { [weak delegate] in
                delegate?.channelController($0, didChangeTypingMembers: $1)
            }
        )
    }
}

extension ClientError {
    class ChannelNotCreatedYet: ClientError {
        override public var localizedDescription: String {
            // swiftlint:disable:next line_length
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
}
