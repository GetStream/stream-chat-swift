//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
    /// Creates a new `CurrentUserController` instance.
    ///
    /// - Returns: A new instance of `CurrentChatUserController`.
    ///
    func currentUserController() -> CurrentChatUserController {
        .init(client: self)
    }
}

/// `CurrentChatUserController` is a controller class which allows observing and mutating the currently logged-in
/// user of `ChatClient`.
///
/// - Note: For an async-await alternative of the `CurrentChatUserController`, please check ``ConnectedUser`` in the async-await supported [state layer](https://getstream.io/chat/docs/sdk/ios/client/state-layer/state-layer-overview/).
public class CurrentChatUserController: DataController, DelegateCallable, DataStoreProvider {
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    private let environment: Environment

    var _basePublishers: Any?
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    var basePublishers: BasePublishers {
        if let value = _basePublishers as? BasePublishers {
            return value
        }
        _basePublishers = BasePublishers(controller: self)
        return _basePublishers as? BasePublishers ?? .init(controller: self)
    }

    /// The observer for the active live location messages.
    private var activeLiveLocationMessagesObserver: BackgroundListDatabaseObserver<ChatMessage, MessageDTO>?

    /// Used for observing the current user changes in a database.
    private lazy var currentUserObserver = createUserObserver()
        .onChange { [weak self] change in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }
                $0.currentUserController(self, didChangeCurrentUser: change)
            }

            /// Only when we have access to the currentUserId is when we should
            /// create the observer for the active live location messages.
            if self?.activeLiveLocationMessagesObserver == nil {
                let observer = self?.createActiveLiveLocationMessagesObserver()
                self?.activeLiveLocationMessagesObserver = observer
                try? observer?.startObserving()
                observer?.onDidChange = { [weak self] _ in
                    self?.delegateCallback { [weak self] _ in
                        guard let self = self else { return }
                        let messages = Array(observer?.items ?? [])
                        self.isSharingLiveLocation = !messages.isEmpty
                    }
                }
            }
        }
        .onFieldChange(\.unreadCount) { [weak self] change in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }
                $0.currentUserController(self, didChangeCurrentUserUnreadCount: change.unreadCount)
            }
        }

    /// A flag to indicate whether the current user is sharing his live location.
    private var isSharingLiveLocation = false {
        didSet {
            if isSharingLiveLocation == oldValue {
                return
            }
            if isSharingLiveLocation {
                delegate?.currentUserControllerDidStartSharingLiveLocation(self)
            } else {
                delegate?.currentUserControllerDidStopSharingLiveLocation(self)
            }
        }
    }

    /// The throttler for limiting the frequency of live location updates.
    private var locationUpdatesThrottler = Throttler(interval: 3, broadcastLatestEvent: true)

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<CurrentChatUserControllerDelegate> = .init()

    /// The currently logged-in user. `nil` if the connection hasn't been fully established yet, or the connection
    /// wasn't successful.
    /// Having a non-nil currentUser does not mean the user is authenticated. Make sure to call `connect()` before performing any API call.
    public var currentUser: CurrentChatUser? {
        startObservingIfNeeded()
        return currentUserObserver.item
    }

    /// The unread messages and channels count for the current user.
    ///
    /// Returns `noUnread` if `currentUser` doesn't exist yet.
    public var unreadCount: UnreadCount {
        currentUser?.unreadCount ?? .noUnread
    }

    /// The worker used to update the current user.
    private lazy var currentUserUpdater = environment.currentUserUpdaterBuilder(
        client.databaseContainer,
        client.apiClient
    )

    /// The worker used to update the current user member for a given channel.
    private lazy var currentMemberUpdater = createMemberUpdater()

    // MARK: - Drafts Properties

    /// The query used for fetching the draft messages.
    private var draftListQuery = DraftListQuery()

    /// Use for observing the current user's draft messages changes.
    private var draftMessagesObserver: BackgroundListDatabaseObserver<DraftMessage, MessageDTO>?

    /// The repository for draft messages.
    private var draftMessagesRepository: DraftMessagesRepository

    /// The token for the next page of draft messages.
    private var draftMessagesNextCursor: String?

    /// A flag to indicate whether all draft messages have been loaded.
    public private(set) var hasLoadedAllDrafts: Bool = false

    /// The current user's draft messages.
    public var draftMessages: [DraftMessage] {
        if let observer = draftMessagesObserver {
            return Array(observer.items)
        }

        let observer = createDraftMessagesObserver(query: draftListQuery)
        return Array(observer.items)
    }

    // MARK: - Init

    /// Creates a new `CurrentUserControllerGeneric`.
    ///
    /// - Parameters:
    ///   - client: The `Client` instance this controller belongs to.
    ///   - environment: The source of internal dependencies
    ///
    init(client: ChatClient, environment: Environment = .init()) {
        self.client = client
        self.environment = environment
        draftMessagesRepository = client.draftMessagesRepository
        super.init()
    }

    /// Synchronize local data with remote. Waits for the client to connect but doesn't initiate the connection itself.
    /// This is to make sure the fetched local data is up-to-date, since the current user data is updated through WebSocket events.
    ///
    /// - Parameter completion: Called when the controller has finished fetching the local data
    ///   and the client connection is established.
    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        startObservingIfNeeded()

        if case let .localDataFetchFailed(error) = state {
            callback { completion?(error) }
            return
        }

        // Unlike the other DataControllers, this one does not make a remote call when synchronising.
        // But we can assume that if we wait for the connection of the WebSocket, it means the local data
        // is in sync with the remote server, so we can set the state to remoteDataFetched.
        client.provideConnectionId { [weak self] result in
            var error: ClientError?
            if case .failure = result {
                error = ClientError.ConnectionNotSuccessful()
            }

            self?.state = error == nil ? .remoteDataFetched : .remoteDataFetchFailed(error!)
            self?.callback { completion?(error) }
        }
    }

    private func startObservingIfNeeded() {
        guard state == .initialized else { return }

        do {
            try currentUserObserver.startObserving()
            state = .localDataFetched
        } catch {
            log.error("""
            Observing current user failed: \(error).\n
            Accessing `currentUser` will always return `nil`, `unreadCount` with `.noUnread`
            """)
            state = .localDataFetchFailed(ClientError(with: error))
        }
    }
}

public extension CurrentChatUserController {
    /// Fetches the token from `tokenProvider` and prepares the current `ChatClient` variables
    /// for the new user.
    ///
    /// If the a token obtained from `tokenProvider` is for another user the
    /// database will be flushed.
    ///
    /// - Parameter completion: The completion to be called when the operation is completed.
    func reloadUserIfNeeded(completion: ((Error?) -> Void)? = nil) {
        client.authenticationRepository.refreshToken { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Updates the current user data.
    ///
    /// By default all data is `nil`, and it won't be updated unless a value is provided.
    ///
    /// - Note: This operation does a partial user update which keeps existing data if not modified. Use ``unsetProperties`` for clearing the existing state.
    ///
    /// - Parameters:
    ///   - name: Optionally provide a new name to be updated.
    ///   - imageURL: Optionally provide a new image to be updated.
    ///   - privacySettings: The privacy settings of the user. Example: If the user does not want to expose typing events or read events.
    ///   - role: The role for the user.
    ///   - teamsRole: The role for the user in a specific team. Example: `["teamId": "role"]`.
    ///   - userExtraData: Optionally provide new user extra data to be updated.
    ///   - unsetProperties: Remove existing properties from the user. For example, `image` or `name`.
    ///   - completion: Called when user is successfuly updated, or with error.
    func updateUserData(
        name: String? = nil,
        imageURL: URL? = nil,
        privacySettings: UserPrivacySettings? = nil,
        role: UserRole? = nil,
        teamsRole: [TeamId: UserRole]? = nil,
        userExtraData: [String: RawJSON] = [:],
        unsetProperties: Set<String> = [],
        completion: ((Error?) -> Void)? = nil
    ) {
        guard let currentUserId = client.currentUserId else {
            completion?(ClientError.CurrentUserDoesNotExist())
            return
        }

        currentUserUpdater.updateUserData(
            currentUserId: currentUserId,
            name: name,
            imageURL: imageURL,
            privacySettings: privacySettings,
            role: role,
            teamsRole: teamsRole,
            userExtraData: userExtraData,
            unset: unsetProperties
        ) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Updates the current user member data in a specific channel.
    ///
    /// **Note**: If you want to observe member changes in real-time, use the `ChatClient.memberController()`.
    ///
    /// - Parameters:
    ///   - extraData: The additional data to be added to the member object.
    ///   - unsetProperties: The properties to be removed from the member object.
    ///   - channelId: The channel where the member data is updated.
    ///   - completion: Returns the updated member object or an error if the update fails.
    func updateMemberData(
        _ extraData: [String: RawJSON],
        unsetProperties: [String]? = nil,
        in channelId: ChannelId,
        completion: ((Result<ChatChannelMember, Error>) -> Void)? = nil
    ) {
        guard let currentUserId = client.currentUserId else {
            completion?(.failure(ClientError.CurrentUserDoesNotExist()))
            return
        }

        currentMemberUpdater.partialUpdate(
            userId: currentUserId,
            in: channelId,
            updates: MemberUpdatePayload(extraData: extraData),
            unset: unsetProperties
        ) { result in
            self.callback {
                completion?(result)
            }
        }
    }

    func loadActiveLiveLocationMessages(completion: ((Result<[SharedLocation], Error>) -> Void)? = nil) {
        currentUserUpdater.loadActiveLiveLocations { result in
            self.callback {
                completion?(result)
            }
        }
    }

    /// Updates the location of all the active live location messages for the current user.
    ///
    /// The updates are throttled to avoid sending too many requests.
    ///
    /// - Parameter location: The new location to be updated.
    func updateLiveLocation(_ location: LocationInfo) {
        guard let messages = activeLiveLocationMessagesObserver?.items, !messages.isEmpty else {
            return
        }

        locationUpdatesThrottler.execute { [weak self] in
            for message in messages {
                guard let cid = message.cid else { continue }
                let messageController = self?.client.messageController(cid: cid, messageId: message.id)
                messageController?.updateLiveLocation(location)
            }
        }
    }

    /// Fetches the most updated devices and syncs with the local database.
    /// - Parameter completion: Called when the devices are synced successfully, or with error.
    func synchronizeDevices(completion: ((Error?) -> Void)? = nil) {
        guard let currentUserId = client.currentUserId else {
            completion?(ClientError.CurrentUserDoesNotExist())
            return
        }

        currentUserUpdater.fetchDevices(currentUserId: currentUserId) { result in
            self.callback { completion?(result.error) }
        }
    }

    /// Registers the current user's device for push notifications.
    /// - Parameters:
    ///   - pushDevice: The device information required for the desired push provider.
    ///   - completion: Callback when device is successfully registered, or failed with error.
    func addDevice(_ pushDevice: PushDevice, completion: ((Error?) -> Void)? = nil) {
        guard let currentUserId = client.currentUserId else {
            completion?(ClientError.CurrentUserDoesNotExist())
            return
        }

        currentUserUpdater.addDevice(
            deviceId: pushDevice.deviceId,
            pushProvider: pushDevice.pushProvider,
            providerName: pushDevice.providerName,
            currentUserId: currentUserId
        ) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Removes a registered device from the current user.
    /// `connectUser` must be called before calling this.
    /// - Parameters:
    ///   - id: Device id to be removed. You can obtain registered devices via `currentUser.devices`.
    ///   If `currentUser.devices` is not up-to-date, please make an `synchronize` call.
    ///   - completion: Called when device is successfully deregistered, or with error.
    func removeDevice(id: DeviceId, completion: ((Error?) -> Void)? = nil) {
        guard let currentUserId = client.currentUserId else {
            completion?(ClientError.CurrentUserDoesNotExist())
            return
        }

        currentUserUpdater.removeDevice(id: id, currentUserId: currentUserId) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Marks all channels for a user as read.
    ///
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func markAllRead(completion: ((Error?) -> Void)? = nil) {
        currentUserUpdater.markAllRead { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Deletes all the local downloads of file attachments.
    ///
    /// - Parameter completion: Called when files have been deleted or when an error occured.
    func deleteAllLocalAttachmentDownloads(completion: ((Error?) -> Void)? = nil) {
        currentUserUpdater.deleteAllLocalAttachmentDownloads { error in
            guard let completion else { return }
            self.callback {
                completion(error)
            }
        }
    }

    /// Fetches all the unread information from the current user.
    ///
    ///  - Parameter completion: Called when the API call is finished.
    ///  Returns the current user unreads or an error if the API call fails.
    ///
    /// Note: This is a one-time request, it is not observable.
    func loadAllUnreads(completion: @escaping ((Result<CurrentUserUnreads, Error>) -> Void)) {
        currentUserUpdater.loadAllUnreads { result in
            self.callback {
                completion(result)
            }
        }
    }

    /// Get all blocked users.
    ///
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func loadBlockedUsers(completion: @escaping (Result<[BlockedUserDetails], Error>) -> Void) {
        currentUserUpdater.loadBlockedUsers { result in
            self.callback {
                completion(result)
            }
        }
    }

    /// Loads the draft messages for the current user.
    ///
    /// It will load the first page of drafts of the current user.
    /// `loadMoreDraftMessages` can be used to load the next pages.
    ///
    /// - Parameters:
    ///  - query: The query for filtering the drafts.
    ///  - completion: Called when the API call is finished.
    ///  It is optional since it can be observed from the delegate events.
    func loadDraftMessages(
        query: DraftListQuery = DraftListQuery(),
        completion: ((Result<[DraftMessage], Error>) -> Void)? = nil
    ) {
        draftListQuery = query
        createDraftMessagesObserver(query: query)
        draftMessagesRepository.loadDrafts(query: query) { result in
            self.callback {
                switch result {
                case let .success(response):
                    self.draftMessagesNextCursor = response.next
                    self.hasLoadedAllDrafts = response.next == nil
                    completion?(.success(response.drafts))
                case let .failure(error):
                    completion?(.failure(error))
                }
            }
        }
    }

    /// Loads more draft messages for the current user.
    ///
    /// - Parameters:
    ///  - limit: The number of draft messages to load. If `nil`, the default limit will be used.
    ///  - completion: Called when the API call is finished.
    ///  It is optional since it can be observed from the delegate events.
    func loadMoreDraftMessages(
        limit: Int? = nil,
        completion: ((Result<[DraftMessage], Error>) -> Void)? = nil
    ) {
        guard let nextCursor = draftMessagesNextCursor else {
            completion?(.success([]))
            return
        }

        let limit = limit ?? draftListQuery.pagination.pageSize
        var updatedQuery = draftListQuery
        updatedQuery.pagination = Pagination(pageSize: limit, cursor: nextCursor)

        draftMessagesRepository.loadDrafts(query: updatedQuery) { result in
            self.callback {
                switch result {
                case let .success(response):
                    self.draftMessagesNextCursor = response.next
                    self.hasLoadedAllDrafts = response.next == nil
                    completion?(.success(response.drafts))
                case let .failure(error):
                    completion?(.failure(error))
                }
            }
        }
    }

    /// Deletes the draft message of the given channel or thread.
    func deleteDraftMessage(
        for cid: ChannelId,
        threadId: MessageId? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        draftMessagesRepository.deleteDraft(for: cid, threadId: threadId) { error in
            self.callback {
                completion?(error)
            }
        }
    }
}

// MARK: - Environment

extension CurrentChatUserController {
    struct Environment {
        var currentUserObserverBuilder: (
            _ database: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<CurrentUserDTO>,
            _ itemCreator: @escaping (CurrentUserDTO) throws -> CurrentChatUser,
            _ fetchedResultsControllerType: NSFetchedResultsController<CurrentUserDTO>.Type
        ) -> BackgroundEntityDatabaseObserver<CurrentChatUser, CurrentUserDTO> = BackgroundEntityDatabaseObserver.init

        var currentUserActiveLiveLocationMessagesObserverBuilder: (
            _ database: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<MessageDTO>,
            _ itemCreator: @escaping (MessageDTO) throws -> ChatMessage,
            _ fetchedResultsControllerType: NSFetchedResultsController<MessageDTO>.Type
        ) -> BackgroundListDatabaseObserver<ChatMessage, MessageDTO> = {
            .init(
                database: $0,
                fetchRequest: $1,
                itemCreator: $2,
                itemReuseKeyPaths: (\ChatMessage.id, \MessageDTO.id),
                fetchedResultsControllerType: $3
            )
        }
        
        var draftMessagesObserverBuilder: (
            _ database: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<MessageDTO>,
            _ itemCreator: @escaping (MessageDTO) throws -> DraftMessage
        ) -> BackgroundListDatabaseObserver<DraftMessage, MessageDTO> = {
            .init(database: $0, fetchRequest: $1, itemCreator: $2, itemReuseKeyPaths: (\DraftMessage.id, \MessageDTO.id))
        }

        var currentUserUpdaterBuilder = CurrentUserUpdater.init
    }
}

// MARK: - Private

private extension EntityChange where Item == UnreadCount {
    var unreadCount: UnreadCount {
        switch self {
        case let .create(count):
            return count
        case let .update(count):
            return count
        case .remove:
            return .noUnread
        }
    }
}

private extension CurrentChatUserController {
    func createUserObserver() -> BackgroundEntityDatabaseObserver<CurrentChatUser, CurrentUserDTO> {
        environment.currentUserObserverBuilder(
            client.databaseContainer,
            CurrentUserDTO.defaultFetchRequest,
            { try $0.asModel() },
            NSFetchedResultsController<CurrentUserDTO>.self
        )
    }

    func createActiveLiveLocationMessagesObserver() -> BackgroundListDatabaseObserver<ChatMessage, MessageDTO>? {
        guard let currentUserId = client.currentUserId else {
            return nil
        }
        return environment.currentUserActiveLiveLocationMessagesObserverBuilder(
            client.databaseContainer,
            MessageDTO.currentUserActiveLiveLocationMessagesFetchRequest(
                currentUserId: currentUserId,
                channelId: nil
            ),
            { try $0.asModel() },
            NSFetchedResultsController<MessageDTO>.self
        )
    }
    
    private func createMemberUpdater() -> ChannelMemberUpdater {
        .init(database: client.databaseContainer, apiClient: client.apiClient)
    }

    @discardableResult
    private func createDraftMessagesObserver(query: DraftListQuery) -> BackgroundListDatabaseObserver<DraftMessage, MessageDTO> {
        let observer = environment.draftMessagesObserverBuilder(
            client.databaseContainer,
            MessageDTO.draftMessagesFetchRequest(query: query),
            { DraftMessage(try $0.asModel()) }
        )
        observer.onDidChange = { [weak self] _ in
            guard let self = self else { return }
            self.delegateCallback {
                $0.currentUserController(self, didChangeDraftMessages: self.draftMessages)
            }
        }
        try? observer.startObserving()
        draftMessagesObserver = observer
        return observer
    }
}

// MARK: - Delegates

/// `CurrentChatUserController` uses this protocol to communicate changes to its delegate.
public protocol CurrentChatUserControllerDelegate: AnyObject {
    /// The controller observed a change in the `UnreadCount`.
    func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeCurrentUserUnreadCount: UnreadCount
    )

    /// The controller observed a change in the `CurrentChatUser` entity.
    func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeCurrentUser: EntityChange<CurrentChatUser>
    )

    /// The current user has currently active live location attachments.
    func currentUserControllerDidStartSharingLiveLocation(
        _ controller: CurrentChatUserController
    )

    /// The current user has no active live location attachments.
    func currentUserControllerDidStopSharingLiveLocation(
        _ controller: CurrentChatUserController
    )

    /// The controller observed a change in the draft messages.
    func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeDraftMessages draftMessages: [DraftMessage]
    )
}

public extension CurrentChatUserControllerDelegate {
    func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeCurrentUserUnreadCount: UnreadCount
    ) {}

    func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeCurrentUser: EntityChange<CurrentChatUser>
    ) {}

    func currentUserControllerDidStartSharingLiveLocation(
        _ controller: CurrentChatUserController
    ) {}

    func currentUserControllerDidStopSharingLiveLocation(
        _ controller: CurrentChatUserController
    ) {}

    func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeDraftMessages draftMessages: [DraftMessage]
    ) {}
}

public extension CurrentChatUserController {
    /// Set the delegate of `CurrentUserController` to observe the changes in the system.
    var delegate: CurrentChatUserControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }
}

// MARK: - Deprecations

public extension CurrentChatUserController {
    @available(
        *,
        deprecated,
        message: "use addDevice(_pushDevice:) instead. This deprecated function doesn't correctly support multiple push providers."
    )
    func addDevice(token: Data, pushProvider: PushProvider = .apn, completion: ((Error?) -> Void)? = nil) {
        addDevice(.apn(token: token), completion: completion)
    }
}
