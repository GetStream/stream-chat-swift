//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which searches messages, users and channels with one request.
///
/// Searches are debounced: 500ms for 1-2 characters, 300ms for 3 or more.
/// Calling ``search(text:)`` or ``search(query:)`` again cancels the previous search.
/// The superseded call returns the current results rather than throwing, so typing does not surface an error per keystroke.
///
/// Results are kept in ``UnifiedSearchState`` and are not updated by events.
/// Channels in the results have no members, messages, reads or unread counts. Load the channel when the user opens it.
///
/// - Important: The unified search endpoint is in beta.
/// - Note: For a delegate based alternative, please check ``UnifiedSearchController``.
public class UnifiedSearch: @unchecked Sendable {
    private let authenticationRepository: AuthenticationRepository
    private let repository: UnifiedSearchRepository
    private let searchDebouncer: AsyncSearchDebouncer
    @MainActor private var stateBuilder: StateBuilder<UnifiedSearchState>

    init(
        client: ChatClient,
        debouncePolicy: SearchDebouncePolicy = .default
    ) {
        authenticationRepository = client.authenticationRepository
        repository = client.unifiedSearchRepository
        searchDebouncer = AsyncSearchDebouncer(policy: debouncePolicy)
        stateBuilder = StateBuilder { UnifiedSearchState() }
    }

    // MARK: - Accessing the State

    /// An observable object representing the current state of the search.
    @MainActor public var state: UnifiedSearchState { stateBuilder.state }

    // MARK: - Search Results

    /// Searches messages, users and channels with the specified text and replaces ``UnifiedSearchState/results``.
    ///
    /// Text which is empty after removing whitespace clears the results without a request.
    ///
    /// - Parameter text: The search text. The backend rejects text longer than 80 characters.
    ///
    /// - Throws: An error while communicating with the Stream API. A failing section does not throw, see ``UnifiedSearchSection/error``.
    /// - Returns: The results for the search text. When a newer search supersedes this one, the current
    /// ``UnifiedSearchState/results`` are returned.
    @discardableResult public func search(text: String) async throws -> UnifiedSearchResults {
        try await search(query: UnifiedSearchQuery(text: text))
    }

    /// Searches the sections of the query and replaces ``UnifiedSearchState/results``.
    ///
    /// A query with empty text clears the results without a request.
    ///
    /// - Parameter query: The query describing the search text, the sections and the page size.
    ///
    /// - Throws: An error while communicating with the Stream API. A failing section does not throw, see ``UnifiedSearchSection/error``.
    /// - Returns: The results for the query. When a newer search supersedes this one, the current
    /// ``UnifiedSearchState/results`` are returned.
    @discardableResult public func search(query: UnifiedSearchQuery) async throws -> UnifiedSearchResults {
        guard !query.text.isEmpty else {
            await clearResults()
            return await state.results
        }
        let results = try await searchDebouncer.schedule(queryLength: query.text.count) { [weak self] in
            guard let self else { throw ClientError("UnifiedSearch was deallocated") }
            return try await self.performSearch(query: query)
        }
        if let results {
            return results
        }
        return await state.results
    }

    /// Loads the next page of the specified sections with one request and adds it to ``UnifiedSearchState/results``.
    ///
    /// Sections which have loaded every result are skipped. When none of the sections has more results, no request is made.
    ///
    /// - Parameter entities: The sections to load the next page for. Defaults to all sections.
    ///
    /// - Throws: An error while communicating with the Stream API, or when no search has completed yet.
    /// A failing section does not throw, see ``UnifiedSearchSection/error``.
    /// - Returns: The loaded page. Sections which were not loaded are empty.
    @discardableResult public func loadMore(
        _ entities: Set<UnifiedSearchEntity> = [.channels, .messages, .users]
    ) async throws -> UnifiedSearchResults {
        let results = await state.results
        guard let baseQuery = results.query else {
            throw ClientError("Call search() before loading more results")
        }
        let cursors = results.nextPageCursors(for: entities)
        guard !cursors.isEmpty else { return UnifiedSearchResults() }
        let pageQuery = UnifiedSearchQuery(
            text: baseQuery.text,
            entities: Set(cursors.keys),
            pageSize: baseQuery.pageSize
        )
        let page = try await repository.search(
            query: pageQuery,
            cursors: cursors,
            currentUserId: authenticationRepository.currentUserId
        )
        await state.handleDidFetchNextPage(page, loadedFor: baseQuery, with: cursors)
        return page
    }

    /// Cancels any pending or in-flight search and clears ``UnifiedSearchState/results``.
    public func clearResults() async {
        await searchDebouncer.cancel()
        await state.clear()
    }

    // MARK: - Private

    private func performSearch(query: UnifiedSearchQuery) async throws -> UnifiedSearchResults {
        // A superseded search must not publish its query. `state.query` is what
        // `handleDidFetchQuery` compares against, so a stale write here would make the
        // winning search discard its own results.
        try Task.checkCancellation()
        await state.setQuery(query)
        let results = try await repository.search(query: query, currentUserId: authenticationRepository.currentUserId)
        try Task.checkCancellation()
        await state.handleDidFetchQuery(query, results: results)
        return results
    }
}
