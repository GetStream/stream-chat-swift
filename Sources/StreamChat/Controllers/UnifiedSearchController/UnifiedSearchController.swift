//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension ChatClient {
    /// Creates a new ``UnifiedSearchController``.
    public func unifiedSearchController() -> UnifiedSearchController {
        .init(client: self)
    }
}

/// A controller which searches messages, users and channels with one request.
///
/// Searches are debounced: 500ms for 1-2 characters, 300ms for 3 or more.
/// Scheduling a new search cancels any pending debounced work, and the response of a superseded search is ignored.
///
/// Results are replaced on every new search and are not updated by events.
/// Channels in the results have no members, messages, reads or unread counts. Load the channel when the user opens it.
///
/// - Important: The unified search endpoint is in beta.
/// - Note: For an async-await alternative, please check ``UnifiedSearch``.
public class UnifiedSearchController: DataController, DelegateCallable, DataStoreProvider, @unchecked Sendable {
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The results of the last completed search, with any loaded pages added.
    public private(set) var results = UnifiedSearchResults()

    /// Set the delegate of `UnifiedSearchController` to observe changes.
    public weak var delegate: UnifiedSearchControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }

    var multicastDelegate: MulticastDelegate<UnifiedSearchControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)
        }
    }

    // Responses of superseded searches are ignored, since requests already in flight are not cancelled.
    private var latestQuery: UnifiedSearchQuery?
    private let repository: UnifiedSearchRepository
    private let searchDebouncer: SearchDebouncer

    init(
        client: ChatClient,
        debouncePolicy: SearchDebouncePolicy = .default
    ) {
        self.client = client
        repository = client.unifiedSearchRepository
        searchDebouncer = SearchDebouncer(policy: debouncePolicy)
        super.init()
    }

    deinit {
        searchDebouncer.cancel()
    }

    /// Searches messages, users and channels with the specified text.
    ///
    /// The `results` property is updated on completion. Text which is empty after removing whitespace clears the results without a request.
    ///
    /// - Parameters:
    ///   - text: The search text. The backend rejects text longer than 80 characters.
    ///   - completion: Called with the results or an error. A failing section does not fail the search, see ``UnifiedSearchSection/error``.
    public func search(
        text: String,
        completion: (@MainActor (Result<UnifiedSearchResults, Error>) -> Void)? = nil
    ) {
        search(query: UnifiedSearchQuery(text: text), completion: completion)
    }

    /// Searches the sections of the query.
    ///
    /// The `results` property is updated on completion. A query with empty text clears the results without a request.
    ///
    /// - Parameters:
    ///   - query: The query describing the search text, the sections and the page size.
    ///   - completion: Called with the results or an error. A failing section does not fail the search, see ``UnifiedSearchSection/error``.
    public func search(
        query: UnifiedSearchQuery,
        completion: (@MainActor (Result<UnifiedSearchResults, Error>) -> Void)? = nil
    ) {
        guard !query.text.isEmpty else {
            clearResults()
            callback { [weak self] in
                completion?(.success(self?.results ?? UnifiedSearchResults()))
            }
            return
        }
        let scheduled = searchDebouncer.schedule(queryLength: query.text.count) { [weak self] in
            self?.fetch(query, completion: completion)
        }
        if !scheduled {
            callback { [weak self] in
                completion?(.success(self?.results ?? UnifiedSearchResults()))
            }
        }
    }

    /// Loads the next page of the specified sections with one request and adds it to `results`.
    ///
    /// Sections which have loaded every result are skipped. When none of the sections has more results, no request is made.
    ///
    /// - Parameters:
    ///   - entities: The sections to load the next page for. Defaults to all sections.
    ///   - completion: Called with the loaded page, where sections which were not loaded are empty, or an error.
    ///   A failing section does not fail the call, see ``UnifiedSearchSection/error``.
    public func loadNextResults(
        _ entities: Set<UnifiedSearchEntity> = [.channels, .messages, .users],
        completion: (@MainActor (Result<UnifiedSearchResults, Error>) -> Void)? = nil
    ) {
        guard let baseQuery = results.query else {
            callback {
                completion?(.failure(ClientError("Call search() before loading more results")))
            }
            return
        }
        let cursors = results.nextPageCursors(for: entities)
        guard !cursors.isEmpty else {
            callback {
                completion?(.success(UnifiedSearchResults()))
            }
            return
        }
        let pageQuery = UnifiedSearchQuery(
            text: baseQuery.text,
            entities: Set(cursors.keys),
            pageSize: baseQuery.pageSize
        )
        repository.search(query: pageQuery, cursors: cursors, currentUserId: client.currentUserId) { [weak self] result in
            self?.callback { [weak self] in
                guard let self else { return }
                switch result {
                case .success(let page):
                    if self.results.applyNextPage(page, loadedFor: baseQuery, with: cursors) {
                        self.notifyDidChangeResults()
                    }
                    completion?(.success(page))
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
        }
    }

    /// Cancels any pending search and clears the current results.
    public func clearResults() {
        searchDebouncer.cancel()
        latestQuery = nil
        guard results.query != nil else { return }
        results = UnifiedSearchResults()
        notifyDidChangeResults()
    }

    // MARK: - Private

    private func fetch(
        _ query: UnifiedSearchQuery,
        completion: (@MainActor (Result<UnifiedSearchResults, Error>) -> Void)?
    ) {
        latestQuery = query
        repository.search(query: query, currentUserId: client.currentUserId) { [weak self] result in
            self?.callback { [weak self] in
                guard let self else { return }
                guard self.latestQuery == query else {
                    completion?(.success(self.results))
                    return
                }
                switch result {
                case .success(let results):
                    self.results = results
                    self.state = .remoteDataFetched
                    self.notifyDidChangeResults()
                    completion?(.success(results))
                case .failure(let error):
                    self.state = .remoteDataFetchFailed(ClientError(with: error))
                    completion?(.failure(error))
                }
            }
        }
    }

    private func notifyDidChangeResults() {
        delegateCallback { [weak self] in
            guard let self else { return }
            $0.controller(self, didChangeResults: self.results)
        }
    }
}

/// `UnifiedSearchController` uses this protocol to communicate changes to its delegate.
public protocol UnifiedSearchControllerDelegate: DataControllerStateDelegate {
    /// The controller updated its results.
    func controller(
        _ controller: UnifiedSearchController,
        didChangeResults results: UnifiedSearchResults
    )
}

extension UnifiedSearchControllerDelegate {
    public func controller(
        _ controller: UnifiedSearchController,
        didChangeResults results: UnifiedSearchResults
    ) {}
}
