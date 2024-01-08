//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

extension ChatClient {
    /// Creates a new `ChannelListController` with the provided channel query.
    /// - Parameter query: The query specify the filter and sorting of the channels the controller should fetch.    ///
    /// - Returns: A new instance of `ChatChannelListController`.
    public func channelListController(query: ChannelListQuery) -> ChatChannelListController {
        .init(query: query, client: self)
    }

    /// Creates a new `ChannelListController` with the provided channel query and filter block.
    ///
    /// When passing `filter`, make sure the runtime logic matches the one expected by the filter passed in the query object.
    /// If they don't match, there can be jumps when loading the list.
    ///
    /// - Parameters:
    ///   - query: The query specify the filter and sorting of the channels the controller should fetch.
    ///   - filter: A block that determines whether the channels belongs to this controller.
    /// - Returns: A new instance of `ChatChannelListController`
    public func channelListController(
        query: ChannelListQuery,
        filter: ((ChatChannel) -> Bool)? = nil
    ) -> ChatChannelListController {
        .init(query: query, client: self, filter: filter)
    }
}

/// `ChatChannelListController` is a controller class which allows observing a list of chat channels based on the provided query.
public class ChatChannelListController: DataController, DelegateCallable, DataStoreProvider {
    /// The query specifying and filtering the list of channels.
    public let query: ChannelListQuery

    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    let eventsController: EventsController

    /// The channels matching the query of this controller.
    ///
    /// To observe changes of the channels, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var channels: LazyCachedMapCollection<ChatChannel> {
        startChannelListObserverIfNeeded()
        return channelListObserver.items
    }

    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var worker: ChannelListUpdater = self.environment
        .channelQueryUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )

    /// A Boolean value that returns whether pagination is finished
    public private(set) var hasLoadedAllPreviousChannels: Bool = false

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<ChatChannelListControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)

            // After setting delegate local changes will be fetched and observed.
            startChannelListObserverIfNeeded()
        }
    }

    private(set) lazy var channelListObserver: ListDatabaseObserverWrapper<ChatChannel, ChannelDTO> = {
        let request = ChannelDTO.channelListFetchRequest(query: self.query, chatClientConfig: client.config)
        let observer = self.environment.createChannelListDatabaseObserver(
            StreamRuntimeCheck._isBackgroundMappingEnabled,
            client.databaseContainer,
            request,
            { try $0.asModel() },
            query.sort.runtimeSorting
        )

        observer.onDidChange = { [weak self] changes in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }
                log.debug("didChangeChannels: \(changes.map(\.debugDescription))")
                $0.controller(self, didChangeChannels: changes)
            }
        }

        observer.onWillChange = { [weak self] in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }

                $0.controllerWillChangeChannels(self)
            }
        }

        return observer
    }()

    var _basePublishers: Any?
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    var basePublishers: BasePublishers {
        if let value = _basePublishers as? BasePublishers {
            return value
        }
        _basePublishers = BasePublishers(controller: self)
        return _basePublishers as? BasePublishers ?? .init(controller: self)
    }

    private let filter: ((ChatChannel) -> Bool)?
    private let environment: Environment

    /// Creates a new `ChannelListController`.
    ///
    /// - Parameters:
    ///   - query: The query used for filtering the channels.
    ///   - client: The `Client` instance this controller belongs to.
    ///   - filter: A block that determines whether the channels belongs to this controller.
    init(
        query: ChannelListQuery,
        client: ChatClient,
        filter: ((ChatChannel) -> Bool)? = nil,
        environment: Environment = .init()
    ) {
        self.client = client
        self.query = query
        self.filter = filter
        self.environment = environment
        eventsController = client.eventsController()
        super.init()
        client.trackChannelListController(self)
        eventsController.delegate = self
    }

    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        startChannelListObserverIfNeeded()
        updateChannelList(completion)
    }

    // MARK: - Actions

    /// Loads next channels from backend.
    ///
    /// - Parameters:
    ///   - limit: Limit for page size.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    public func loadNextChannels(
        limit: Int? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        if hasLoadedAllPreviousChannels {
            completion?(nil)
            return
        }

        let limit = limit ?? query.pagination.pageSize
        var updatedQuery = query
        updatedQuery.pagination = Pagination(pageSize: limit, offset: channels.count)
        worker.update(channelListQuery: updatedQuery) { result in
            switch result {
            case let .success(channels):
                self.hasLoadedAllPreviousChannels = channels.count < limit
                self.callback { completion?(nil) }
            case let .failure(error):
                self.callback { completion?(error) }
            }
        }
    }

    @available(*, deprecated, message: "Please use `markAllRead` available in `CurrentChatUserController`")
    public func markAllRead(completion: ((Error?) -> Void)? = nil) {
        worker.markAllRead { error in
            self.callback {
                completion?(error)
            }
        }
    }

    // MARK: - Internal

    func resetQuery(
        watchedAndSynchedChannelIds: Set<ChannelId>,
        synchedChannelIds: Set<ChannelId>,
        completion: @escaping (Result<(synchedAndWatched: [ChatChannel], unwanted: Set<ChannelId>), Error>) -> Void
    ) {
        let pageSize = query.pagination.pageSize
        worker.resetChannelsQuery(
            for: query,
            pageSize: pageSize,
            watchedAndSynchedChannelIds: watchedAndSynchedChannelIds,
            synchedChannelIds: synchedChannelIds
        ) { [weak self] result in
            switch result {
            case let .success((newChannels, unwantedCids)):
                self?.hasLoadedAllPreviousChannels = newChannels.count < pageSize
                completion(.success((newChannels, unwantedCids)))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Helpers

    private func updateChannelList(
        _ completion: ((_ error: Error?) -> Void)? = nil
    ) {
        let limit = query.pagination.pageSize
        worker.update(
            channelListQuery: query
        ) { [weak self] result in
            switch result {
            case let .success(channels):
                self?.state = .remoteDataFetched
                self?.hasLoadedAllPreviousChannels = channels.count < limit
                self?.callback { completion?(nil) }
            case let .failure(error):
                self?.state = .remoteDataFetchFailed(ClientError(with: error))
                self?.callback { completion?(error) }
            }
        }
    }

    /// If the `state` of the controller is `initialized`, this method calls `startObserving` on the
    /// `channelListObserver` to fetch the local data and start observing the changes. It also changes
    /// `state` based on the result.
    ///
    /// It's safe to call this method repeatedly.
    ///
    private func startChannelListObserverIfNeeded() {
        guard state == .initialized else { return }
        do {
            try channelListObserver.startObserving()
            state = .localDataFetched
        } catch {
            state = .localDataFetchFailed(ClientError(with: error))
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
        }
    }
}

/// When we receive events, we need to check if a channel should be added or removed from
/// the current query depending on the following events:
/// - Channel created: We analyse if the channel should be added to the current query.
/// - New message sent: This means the channel will reorder and appear on first position,
///   so we also analyse if it should be added to the current query.
/// - Channel is updated: We only check if we should remove it from the current query.
///   We don't try to add it to the current query to not mess with pagination.
extension ChatChannelListController: EventsControllerDelegate {
    public func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        if let channelAddedEvent = event as? NotificationAddedToChannelEvent {
            linkChannelIfNeeded(channelAddedEvent.channel)
        } else if let messageNewEvent = event as? MessageNewEvent {
            linkChannelIfNeeded(messageNewEvent.channel)
        } else if let messageNewEvent = event as? NotificationMessageNewEvent {
            linkChannelIfNeeded(messageNewEvent.channel)
        } else if let updatedChannelEvent = event as? ChannelUpdatedEvent {
            unlinkChannelIfNeeded(updatedChannelEvent.channel)
        } else if let channelVisibleEvent = event as? ChannelVisibleEvent, let channel = dataStore.channel(cid: channelVisibleEvent.cid) {
            linkChannelIfNeeded(channel)
        }
    }

    /// Handles if a channel should be linked to the current query or not.
    private func linkChannelIfNeeded(_ channel: ChatChannel) {
        guard !channels.contains(channel) else { return }
        guard shouldChannelBelongToCurrentQuery(channel) else { return }
        link(channel: channel)
    }

    /// Handles if a channel should be unlinked from the current query or not.
    private func unlinkChannelIfNeeded(_ channel: ChatChannel) {
        guard channels.contains(channel) else { return }
        guard !shouldChannelBelongToCurrentQuery(channel) else { return }
        worker.unlink(channel: channel, with: query)
    }

    /// Checks if the given channel should belong to the current query or not.
    private func shouldChannelBelongToCurrentQuery(_ channel: ChatChannel) -> Bool {
        if let filter = filter {
            return filter(channel)
        }

        guard !client.config.isChannelAutomaticFilteringEnabled else {
            // When auto-filtering is enabled the channel will appear or not automatically if the
            // query matches the DB Predicate. So here we default to saying it always belong to the current query.
            return true
        }

        // Fallback to legacy of checking if a channel should be linked to the current channel list query.
        let deprecatedFallback: () -> Bool? = {
            self.delegate?.controller(self, shouldAddNewChannelToList: channel)
        }

        return deprecatedFallback() ?? true
    }

    /// Links the channel to the current channel list query and starts watching it.
    private func link(channel: ChatChannel) {
        worker.link(channel: channel, with: query) { [weak self] error in
            if let error = error {
                log.error(error)
                return
            }

            self?.worker.startWatchingChannels(withIds: [channel.cid]) { error in
                guard let error = error else { return }
                log.warning(
                    "Failed to start watching linked channel: \(channel.cid), error: \(error.localizedDescription)"
                )
            }
        }
    }
}

extension ChatChannelListController {
    struct Environment {
        var channelQueryUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelListUpdater = ChannelListUpdater.init

        var createChannelListDatabaseObserver: (
            _ isBackground: Bool,
            _ database: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<ChannelDTO>,
            _ itemCreator: @escaping (ChannelDTO) throws -> ChatChannel,
            _ sorting: [SortValue<ChatChannel>]
        )
            -> ListDatabaseObserverWrapper<ChatChannel, ChannelDTO> = {
                ListDatabaseObserverWrapper(isBackground: $0, database: $1, fetchRequest: $2, itemCreator: $3, sorting: $4)
            }
    }
}

extension ChatChannelListController {
    /// Set the delegate of `ChannelListController` to observe the changes in the system.
    public weak var delegate: ChatChannelListControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }
}

/// `ChatChannelListController` uses this protocol to communicate changes to its delegate.
public protocol ChatChannelListControllerDelegate: DataControllerStateDelegate {
    /// The controller will update the list of observed channels.
    ///
    /// - Parameter controller: The controller emitting the change callback.
    ///
    func controllerWillChangeChannels(_ controller: ChatChannelListController)

    /// The controller changed the list of observed channels.
    ///
    /// - Parameters:
    ///   - controller: The controller emitting the change callback.
    ///   - changes: The change to the list of channels.\
    ///
    func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    )

    /// **⚠️ This method is deprecated:** Please use `filter` when initializing a `ChatChannelListController`
    ///
    /// (We are not using @available annotations because they do not get emitted in protocol conformances)
    ///
    /// The controller asks the delegate if the newly inserted `ChatChannel` should be linked to this Controller's query.
    /// Defaults to `true`
    /// - Parameters:
    ///   - controller: The controller,
    ///   - shouldAddNewChannelToList: The newly inserted `ChatChannel` instance. This instance is not linked to the controller's query.
    /// - Returns:
    ///     `true` if channel should be added to the list of observed channels, `false` if channel doesn't exists in this list.
    func controller(
        _ controller: ChatChannelListController,
        shouldAddNewChannelToList channel: ChatChannel
    ) -> Bool

    /// **⚠️ This method is deprecated:** Please use `filter` when initializing a `ChatChannelListController`
    ///
    /// (We are not using @available annotations because they do not get emitted in protocol conformances)
    ///
    /// The controller asks the delegate if the newly updated `ChatChannel` should be linked to this Controller's query.
    /// Defaults to `true`
    /// - Parameters:
    ///   - controller: The controller,
    ///   - shouldListUpdatedChannel: The newly updated `ChatChannel` instance.
    /// - Returns:
    ///     `true` if channel should be added to the list of observed channels, `false` if channel doesn't exists in this list.
    func controller(
        _ controller: ChatChannelListController,
        shouldListUpdatedChannel channel: ChatChannel
    ) -> Bool
}

public extension ChatChannelListControllerDelegate {
    func controllerWillChangeChannels(_ controller: ChatChannelListController) {}

    func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) {}

    @available(*, deprecated, message: "Please use `filter` when initializing a `ChatChannelListController`")
    func controller(_ controller: ChatChannelListController, shouldAddNewChannelToList channel: ChatChannel) -> Bool {
        channel.membership != nil
    }

    @available(*, deprecated, message: "Please use `filter` when initializing a `ChatChannelListController`")
    func controller(_ controller: ChatChannelListController, shouldListUpdatedChannel channel: ChatChannel) -> Bool {
        channel.membership != nil
    }
}

extension ClientError {
    public class FetchFailed: Error {
        public var localizedDescription: String = "Failed to perform fetch request. This is an internal error."
    }
}
