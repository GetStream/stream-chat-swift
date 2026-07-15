//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
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
        filter: (@Sendable (ChatChannel) -> Bool)? = nil
    ) -> ChatChannelListController {
        .init(query: query, client: self, filter: filter)
    }
}

/// `ChatChannelListController` is a controller class which allows observing a list of chat channels based on the provided query.
///
/// - Note: For an async-await alternative of the `ChatChannelListController`, please check ``ChannelList`` in the async-await supported [state layer](https://getstream.io/chat/docs/sdk/ios/client/state-layer/state-layer-overview/).
public class ChatChannelListController: DataController, DelegateCallable, DataStoreProvider, @unchecked Sendable {
    /// The query specifying and filtering the list of channels.
    public internal(set) var query: ChannelListQuery

    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The channels matching the query of this controller.
    ///
    /// To observe changes of the channels, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var channels: [ChatChannel] {
        startChannelListObserverIfNeeded()
        return channelList.backgroundState { $0.channels }
    }

    /// The state layer object which backs this controller.
    ///
    /// All the data and actions come from the state layer which allows sharing the same
    /// implementation between async-await based APIs and controller based APIs. The controller reads
    /// from the non-isolated background state (see ``ChannelList/backgroundState(_:)``), which never
    /// blocks the main thread nor the database queue.
    let channelList: ChannelList

    /// Combine subscriptions observing the non-isolated background state.
    ///
    /// - Note: Mutated only once, on ``ChannelList``'s background state queue, when observing starts
    ///   (see ``startChannelListObserverIfNeeded()``).
    private var cancellables = Set<AnyCancellable>()

    /// The worker used to update current user data.
    private lazy var currentUserUpdater: CurrentUserUpdater = self.environment
        .currentUserUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
    
    /// The validator used to determine if messages can be marked as delivered.
    private let deliveryCriteriaValidator: MessageDeliveryCriteriaValidating

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
        filter: (@Sendable (ChatChannel) -> Bool)? = nil,
        environment: Environment = .init()
    ) {
        self.client = client
        self.query = query
        self.environment = environment
        deliveryCriteriaValidator = environment.deliveryCriteriaValidatorBuilder()
        channelList = environment.channelListBuilder(query, filter, client)
        super.init()
    }

    override public func synchronize(_ completion: (@MainActor (_ error: Error?) -> Void)? = nil) {
        startChannelListObserverIfNeeded()
        client.syncRepository.startTrackingChannelListController(self)
        Task { [weak self] in
            guard let self else { return }
            do {
                let pageSize = self.channelList.backgroundState { $0.query.pagination.pageSize }
                let channels = try await self.channelList.synchronizeBackgroundState()
                let hasLoadedAll = channels.count < pageSize
                self.channelList.backgroundState { $0.hasLoadedAllPreviousChannels = hasLoadedAll }
                // Predefined filters can update the local query representation.
                let updatedQuery = self.channelList.backgroundState { $0.query }
                self.callback {
                    self.hasLoadedAllPreviousChannels = hasLoadedAll
                    self.query = updatedQuery
                    self.state = .remoteDataFetched
                    self.markChannelsAsDeliveredIfNeeded(channels: channels)
                    completion?(nil)
                }
            } catch {
                self.callback {
                    self.state = .remoteDataFetchFailed(ClientError(with: error))
                    completion?(error)
                }
            }
        }
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
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        if hasLoadedAllPreviousChannels {
            callback {
                completion?(nil)
            }
            return
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                let channels = try await self.channelList.loadMoreBackgroundStateChannels(limit: limit)
                let hasLoadedAll = self.channelList.backgroundState { $0.hasLoadedAllPreviousChannels }
                self.callback {
                    self.hasLoadedAllPreviousChannels = hasLoadedAll
                    self.markChannelsAsDeliveredIfNeeded(channels: channels)
                    completion?(nil)
                }
            } catch {
                self.callback { completion?(error) }
            }
        }
    }

    // MARK: - Internal

    func refreshLoadedChannels(completion: @escaping @Sendable (Result<Set<ChannelId>, Error>) -> Void) {
        Task { [channelList] in
            do {
                let channelIds = try await channelList.refreshLoadedBackgroundStateChannels()
                completion(.success(channelIds))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - Helpers
    
    /// Marks channels as delivered if they meet the specified criteria.
    /// - Parameter channels: The channels to evaluate for marking as delivered.
    private func markChannelsAsDeliveredIfNeeded(channels: [ChatChannel]) {
        guard let currentUser = client.currentUserController().currentUser else { return }

        // Extract channels that should be marked as delivered
        let deliveries: [MessageDeliveryInfo] = channels.compactMap { channel in
            guard let message = channel.latestMessages.first else {
                return nil
            }
            guard deliveryCriteriaValidator.canMarkMessageAsDelivered(message, for: currentUser, in: channel) else {
                return nil
            }
            return MessageDeliveryInfo(channelId: channel.cid, messageId: message.id)
        }

        // Only make the API call if there are channels to mark as delivered
        guard !deliveries.isEmpty else { return }

        // Mark channels as delivered
        currentUserUpdater.markMessagesAsDelivered(deliveries) { error in
            if let error = error {
                log.error("Failed to mark channels as delivered: \(error)")
            }
        }
    }

    /// A reentrancy guard for ``startChannelListObserverIfNeeded()``: delegate callbacks can
    /// synchronously read ``channels`` (which starts the observer) while the observer is starting.
    private let isStartingChannelListObserver = AllocatedUnfairLock(false)

    /// If the `state` of the controller is `initialized`, this method builds the state layer's
    /// non-isolated ``ChannelListObservableState`` (which starts observing the database on a
    /// background queue) and starts observing its changes.
    ///
    /// It's safe to call this method repeatedly.
    ///
    private func startChannelListObserverIfNeeded() {
        guard state == .initialized else { return }
        let shouldStart = isStartingChannelListObserver.withLock { isStarting -> Bool in
            guard !isStarting else { return false }
            isStarting = true
            return true
        }
        guard shouldStart else { return }

        // Building the background state starts the database observer and returns the current channels.
        // The closure runs on the background state's serial queue, so subscriptions are set up there.
        let initialChannels: [ChatChannel] = channelList.backgroundState { [weak self] channelListState in
            guard let self else { return channelListState.channels }
            // Predefined filters are resolved when the background state is created.
            self.query = channelListState.query

            // `latestChanges` is published after `channels`, therefore reads of `channels` are
            // guaranteed to be up to date when delegates react to the changes.
            channelListState.$latestChanges
                .dropFirst()
                .sink { [weak self] changes in
                    guard let self else { return }
                    self.delegateCallback { [weak self] in
                        guard let self else {
                            log.warning("Callback called while self is nil")
                            return
                        }
                        log.debug("didChangeChannels: \(changes.map(\.debugDescription))")
                        $0.controller(self, didChangeChannels: changes)
                    }
                }
                .store(in: &self.cancellables)

            return channelListState.channels
        }
        state = .localDataFetched

        // Report the initial local data as insertions (matches the legacy database observer behavior).
        // Dispatched asynchronously because this method can run within the `multicastDelegate.didSet`
        // (invoking the delegate synchronously there would violate exclusive access to the property).
        let initialChanges: [ListChange<ChatChannel>] = initialChannels
            .enumerated()
            .map { .insert($1, index: IndexPath(item: $0, section: 0)) }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegateCallback { [weak self] in
                guard let self else { return }
                $0.controller(self, didChangeChannels: initialChanges)
            }
        }
    }
}

extension ChatChannelListController {
    struct Environment {
        var channelListBuilder: (
            _ query: ChannelListQuery,
            _ dynamicFilter: (@Sendable (ChatChannel) -> Bool)?,
            _ client: ChatClient
        ) -> ChannelList = { query, dynamicFilter, client in
            ChannelList(query: query, dynamicFilter: dynamicFilter, client: client)
        }

        var currentUserUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> CurrentUserUpdater = CurrentUserUpdater.init
        
        var deliveryCriteriaValidatorBuilder: () -> MessageDeliveryCriteriaValidating = {
            MessageDeliveryCriteriaValidator()
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
