//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

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
/// Scheduling a new search cancels any pending debounced work and ignores results from
/// previously in-flight requests.
public class ChatChannelSearchController: DataController, @unchecked Sendable {
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// Called when a new channel list controller has been created for a search, before remote data is fetched.
    public var didCreateChannelListController: (@MainActor (ChatChannelListController) -> Void)?

    /// The channel list controller backing the latest search results.
    public private(set) var channelListController: ChatChannelListController?

    /// The channels matching the last search.
    public var channels: [ChatChannel] {
        channelListController?.channels ?? []
    }

    private let searchDebouncer: SearchDebouncer

    init(client: ChatClient, debouncePolicy: SearchDebouncePolicy = .default) {
        self.client = client
        searchDebouncer = SearchDebouncer(policy: debouncePolicy)
        super.init()
    }

    deinit {
        searchDebouncer.cancel()
    }

    /// Searches channels whose name matches the given text.
    ///
    /// - Parameters:
    ///   - text: The channel name search text.
    ///   - completion: Called when the controller has finished fetching remote data.
    public func search(
        text: String,
        completion: (@MainActor (_ error: Error?) -> Void)? = nil
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            clearResults()
            callback { completion?(nil) }
            return
        }

        guard let currentUserId = client.currentUserId else {
            callback {
                completion?(ClientError.CurrentUserDoesNotExist("For channel search, a current user must be logged in"))
            }
            return
        }

        let scheduled = searchDebouncer.schedule(queryLength: trimmed.count) { [weak self] isCurrent in
            guard let self else { return }

            var query = ChannelListQuery(
                filter: .and([
                    .autocomplete(.name, text: trimmed),
                    .containMembers(userIds: [currentUserId])
                ])
            )
            // Do not watch the query when searching.
            query.options = []

            let controller = self.client.channelListController(query: query)
            self.channelListController = controller
            self.state = .localDataFetched
            self.callback {
                self.didCreateChannelListController?(controller)
            }

            controller.synchronize { [weak self] error in
                guard let self, isCurrent() else { return }
                self.state = error == nil ? .remoteDataFetched : .remoteDataFetchFailed(ClientError(with: error))
                self.callback { completion?(error) }
            }
        }
        if !scheduled {
            callback { completion?(nil) }
        }
    }

    /// Cancels any pending or in-flight search and clears the current results.
    ///
    /// Call this when the search UI is cleared or dismissed. Without it, a search that was
    /// already debounced still reaches the backend after the user emptied the search field,
    /// and its results are installed into ``channelListController``.
    public func clearResults() {
        searchDebouncer.cancel()
        channelListController = nil
        state = .localDataFetched
    }

    /// Loads the next page of channels for the current search.
    public func loadNextChannels(
        limit: Int? = nil,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        guard let channelListController else {
            callback {
                completion?(ClientError("You should make a search before calling for next page."))
            }
            return
        }
        channelListController.loadNextChannels(limit: limit, completion: completion)
    }
}
