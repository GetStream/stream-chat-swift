//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
    /// Creates a new `ChatChannelSearchController`.
    ///
    /// - Returns: A new instance of `ChatChannelSearchController`.
    func channelSearchController() -> ChatChannelSearchController {
        .init(client: self)
    }
}

/// `ChatChannelSearchController` searches channels by name.
///
/// Text searches are debounced: 500ms for 1-2 characters, 300ms for 3 or more.
/// Scheduling a new search cancels any pending debounced work.
///
/// Results stay live: once a search has run, changes to the matching channels (a new message,
/// a name change, a member update) are reported through the delegate.
public class ChatChannelSearchController: DataController, DelegateCallable, DataStoreProvider, @unchecked Sendable {
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    private let environment: Environment
    private let searchDebouncer: SearchDebouncer

    /// The local identity of the results this controller observes.
    ///
    /// It is stable for the controller's lifetime, so consecutive searches replace each other in
    /// one place instead of leaving a query behind in the database per search text.
    let explicitQueryHash = UUID().uuidString

    /// The query the results are linked to before any search has run.
    lazy var query: ChannelListQuery = .searchResults(explicitQueryHash: explicitQueryHash)

    /// Copy of the last search query, used for pagination.
    var lastQuery: ChannelListQuery?

    /// The channels matching the last search.
    ///
    /// To observe changes of the channels, set your class as a delegate of this controller.
    public var channels: [ChatChannel] {
        startObserversIfNeeded()
        return channelsObserver?.items ?? []
    }

    /// A Boolean value that returns whether the last page of the current search has been loaded.
    public private(set) var hasLoadedAllChannels: Bool = false

    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var channelListUpdater: ChannelListUpdater = self.environment
        .channelListUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )

    /// Used for observing the database for changes.
    private var channelsObserver: BackgroundListDatabaseObserver<ChatChannel, ChannelDTO>?

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<ChatChannelSearchControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)

            // After setting delegate local changes will be fetched and observed.
            startObserversIfNeeded()
        }
    }

    init(
        client: ChatClient,
        environment: Environment = .init(),
        debouncePolicy: SearchDebouncePolicy = .default
    ) {
        self.client = client
        self.environment = environment
        searchDebouncer = SearchDebouncer(policy: debouncePolicy)

        super.init()

        setChannelsObserver()
    }

    deinit {
        searchDebouncer.cancel()
        let query = self.query
        client.databaseContainer.write { session in
            session.delete(query: query)
        }
    }

    // MARK: - Actions

    /// Searches channels whose name matches the given text.
    ///
    /// When this function is called, the ``channels`` property of this controller refreshes with
    /// the channels matching the text, and the delegate function `didChangeChannels` is called.
    ///
    /// - Parameters:
    ///   - text: The channel name search text.
    ///   - completion: Called when the controller has finished fetching remote data.
    ///   If the data fetching fails, the error variable contains more details about the problem.
    public func search(
        text: String,
        completion: (@MainActor (_ error: Error?) -> Void)? = nil
    ) {
        startObserversIfNeeded()

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            clearResults(completion: completion)
            return
        }

        guard let currentUserId = client.currentUserId else {
            callback {
                completion?(ClientError.CurrentUserDoesNotExist("For channel search, a current user must be logged in"))
            }
            return
        }

        var query = ChannelListQuery(
            filter: .and([
                .autocomplete(.name, text: trimmed),
                .containMembers(userIds: [currentUserId])
            ])
        )
        // Do not watch the query when searching.
        query.options = []

        scheduleSearch(query: query, completion: completion)
    }

    /// Searches channels for the given query.
    ///
    /// When this function is called, the ``channels`` property of this controller refreshes with
    /// the channels matching the query, and the delegate function `didChangeChannels` is called.
    ///
    /// - Note: A query built around a text-search operator (`.autocomplete`, `.queryText`) is
    /// debounced on the length of that text, even when combined with other filters. A query
    /// with no search text is not typed character by character, so it runs right away.
    ///
    /// - Parameters:
    ///   - query: Search query.
    ///   - completion: Called when the controller has finished fetching remote data.
    ///   If the data fetching fails, the error variable contains more details about the problem.
    public func search(
        query: ChannelListQuery,
        completion: (@MainActor (_ error: Error?) -> Void)? = nil
    ) {
        startObserversIfNeeded()

        scheduleSearch(query: query, completion: completion)
    }

    /// Cancels any pending search and clears the current search results.
    ///
    /// Call this when the search UI is cleared or dismissed.
    ///
    /// - Parameter completion: Called when the local search results have been cleared.
    public func clearResults(completion: (@MainActor (_ error: Error?) -> Void)? = nil) {
        searchDebouncer.cancel()
        guard let clearedQuery = lastQuery else {
            callback { completion?(nil) }
            return
        }
        lastQuery = nil
        hasLoadedAllChannels = false
        client.databaseContainer.write({ session in
            // Only the link between the query and its results is removed, the channels stay cached.
            session.channelListQuery(clearedQuery)?.channels.removeAll()
        }, completion: { [weak self] error in
            self?.callback { completion?(error) }
        })
    }

    /// Loads the next page of channels for the current search.
    ///
    /// - Parameters:
    ///   - limit: Limit for page size.
    ///   - completion: Called when the controller has finished fetching remote data.
    ///   If the data fetching fails, the error variable contains more details about the problem.
    public func loadNextChannels(
        limit: Int? = nil,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        guard let lastQuery else {
            callback {
                completion?(ClientError("You should make a search before calling for next page."))
            }
            return
        }
        if hasLoadedAllChannels {
            callback { completion?(nil) }
            return
        }

        let limit = limit ?? lastQuery.pagination.pageSize
        var updatedQuery = lastQuery
        updatedQuery.pagination = Pagination(pageSize: limit, offset: channels.count)

        // Pagination extends the current search, so it is not debounced.
        update(query: updatedQuery, limit: limit, updatesState: false, completion: completion)
    }

    // MARK: - Helpers

    private func scheduleSearch(
        query: ChannelListQuery,
        completion: (@MainActor (_ error: Error?) -> Void)?
    ) {
        let scheduled = searchDebouncer.schedule(filter: query.filter) { [weak self] in
            self?.executeSearch(query: query, completion: completion)
        }
        if !scheduled {
            callback { completion?(nil) }
        }
    }

    private func executeSearch(
        query: ChannelListQuery,
        completion: (@MainActor (_ error: Error?) -> Void)?
    ) {
        var query = query
        query.explicitQueryHash = explicitQueryHash

        lastQuery = query
        hasLoadedAllChannels = false

        // The local predicate and the sorting follow the query, so the observer is rebuilt.
        resetChannelsObserver()

        update(
            query: query,
            limit: query.pagination.pageSize,
            updatesState: true,
            completion: completion
        )
    }

    private func update(
        query: ChannelListQuery,
        limit: Int,
        updatesState: Bool,
        completion: (@MainActor (_ error: Error?) -> Void)?
    ) {
        channelListUpdater.update(channelListQuery: query) { [weak self] result in
            guard let self else { return }

            switch result {
            case let .success(updateResult):
                hasLoadedAllChannels = updateResult.channels.count < limit
                if updatesState {
                    state = .remoteDataFetched
                }
                callback { completion?(nil) }
            case let .failure(error):
                if updatesState {
                    state = .remoteDataFetchFailed(ClientError(with: error))
                }
                callback { completion?(error) }
            }
        }
    }

    private func startObserversIfNeeded() {
        guard state == .initialized else { return }
        do {
            try channelsObserver?.startObserving()

            state = .localDataFetched
        } catch {
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
            state = .localDataFetchFailed(ClientError(with: error))
        }
    }

    private func setChannelsObserver() {
        let query = lastQuery ?? self.query
        let observer = environment.createChannelListDatabaseObserver(
            client.databaseContainer,
            ChannelDTO.channelListFetchRequest(query: query, chatClientConfig: client.config),
            { try $0.asModel() },
            query.runtimeSortingValues
        )

        observer.onDidChange = { [weak self] changes in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }
                $0.controller(self, didChangeChannels: changes)
            }
        }

        channelsObserver = observer
    }

    private func resetChannelsObserver() {
        setChannelsObserver()
        state = .initialized
        startObserversIfNeeded()
    }
}

extension ChatChannelSearchController {
    struct Environment {
        var channelListUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelListUpdater = ChannelListUpdater.init

        var createChannelListDatabaseObserver: (
            _ database: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<ChannelDTO>,
            _ itemCreator: @escaping (ChannelDTO) throws -> ChatChannel,
            _ sort: [SortValue<ChatChannel>]
        )
            -> BackgroundListDatabaseObserver<ChatChannel, ChannelDTO> = {
                BackgroundListDatabaseObserver(
                    database: $0,
                    fetchRequest: $1,
                    itemCreator: $2,
                    itemReuseKeyPaths: (\ChatChannel.cid.rawValue, \ChannelDTO.cid),
                    runtimeSorting: $3
                )
            }
    }
}

extension ChatChannelSearchController {
    /// Set the delegate of `ChatChannelSearchController` to observe the changes in the system.
    public weak var delegate: ChatChannelSearchControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }
}

/// `ChatChannelSearchController` uses this protocol to communicate changes to its delegate.
public protocol ChatChannelSearchControllerDelegate: DataControllerStateDelegate {
    /// The controller changed the list of observed channels.
    ///
    /// - Parameters:
    ///   - controller: The controller emitting the change callback.
    ///   - changes: The change to the list of channels.
    func controller(
        _ controller: ChatChannelSearchController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    )
}

public extension ChatChannelSearchControllerDelegate {
    func controller(
        _ controller: ChatChannelSearchController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) {}
}
