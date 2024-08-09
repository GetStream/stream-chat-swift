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

    private(set) lazy var channelListObserver: BackgroundListDatabaseObserver<ChatChannel, ChannelDTO> = {
        let request = ChannelDTO.channelListFetchRequest(query: self.query, chatClientConfig: client.config)
        let observer = self.environment.createChannelListDatabaseObserver(
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
    var basePublishers: BasePublishers {
        if let value = _basePublishers as? BasePublishers {
            return value
        }
        _basePublishers = BasePublishers(controller: self)
        return _basePublishers as? BasePublishers ?? .init(controller: self)
    }

    private let filter: ((ChatChannel) -> Bool)?
    private let environment: Environment
    private lazy var channelListLinker: ChannelListLinker = self.environment
        .channelListLinkerBuilder(
            query, filter, client.config, client.databaseContainer, worker
        )

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
        super.init()
    }

    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        startChannelListObserverIfNeeded()
        channelListLinker.start(with: client.eventNotificationCenter)
        client.syncRepository.startTrackingChannelListController(self)
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

    func refreshLoadedChannels(completion: @escaping (Result<Set<ChannelId>, Error>) -> Void) {
        let channelCount = channelListObserver.items.count
        worker.refreshLoadedChannels(for: query, channelCount: channelCount, completion: completion)
    }
    
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

extension ChatChannelListController {
    struct Environment {
        var channelQueryUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelListUpdater = ChannelListUpdater.init

        var channelListLinkerBuilder: (
            _ query: ChannelListQuery,
            _ filter: ((ChatChannel) -> Bool)?,
            _ clientConfig: ChatClientConfig,
            _ databaseContainer: DatabaseContainer,
            _ worker: ChannelListUpdater
        ) -> ChannelListLinker = ChannelListLinker.init
        
        var createChannelListDatabaseObserver: (
            _ database: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<ChannelDTO>,
            _ itemCreator: @escaping (ChannelDTO) throws -> ChatChannel,
            _ sorting: [SortValue<ChatChannel>]
        )
            -> BackgroundListDatabaseObserver<ChatChannel, ChannelDTO> = {
                BackgroundListDatabaseObserver(
                    database: $0,
                    fetchRequest: $1,
                    itemCreator: $2,
                    itemReuseKeyPaths: (\ChatChannel.cid.rawValue, \ChannelDTO.cid),
                    sorting: $3
                )
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
}

public extension ChatChannelListControllerDelegate {
    func controllerWillChangeChannels(_ controller: ChatChannelListController) {}

    func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) {}
}

extension ClientError {
    public final class FetchFailed: Error {
        public let localizedDescription: String = "Failed to perform fetch request. This is an internal error."
    }
}
