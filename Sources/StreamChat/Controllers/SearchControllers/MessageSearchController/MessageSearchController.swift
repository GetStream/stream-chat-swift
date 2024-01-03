//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
    /// Creates a new `MessageSearchController` with the provided message query.
    ///
    /// - Parameter query: The query specify the filter of the messages the controller should fetch.
    ///
    /// - Returns: A new instance of `MessageSearchController`.
    ///
    func messageSearchController() -> ChatMessageSearchController {
        .init(client: self)
    }
}

/// `ChatMessageSearchController` is a controller class which allows observing a list of messages based on the provided query.
public class ChatMessageSearchController: DataController, DelegateCallable, DataStoreProvider {
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient
    private let environment: Environment

    init(client: ChatClient, environment: Environment = .init()) {
        self.client = client
        self.environment = environment

        super.init()

        setMessagesObserver()
    }

    deinit {
        let query = self.query
        client.databaseContainer.write { session in
            session.deleteQuery(query)
        }
    }

    /// Filter hash this controller observes.
    let explicitFilterHash = UUID().uuidString

    private var nextPageCursor: String?

    lazy var query: MessageSearchQuery = {
        // Filter is just a mock, explicit hash will override it
        var query = MessageSearchQuery(channelFilter: .exists(.cid), messageFilter: .queryText(""))
        query.filterHash = explicitFilterHash

        return query
    }()

    /// Copy of last search query made, used for getting next page.
    var lastQuery: MessageSearchQuery?

    /// The messages matching the query of this controller.
    ///
    /// To observe changes of the messages, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    public var messages: LazyCachedMapCollection<ChatMessage> {
        startObserversIfNeeded()
        return messagesObserver?.items ?? []
    }

    lazy var messageUpdater = self.environment
        .messageUpdaterBuilder(
            client.config.isLocalStorageEnabled,
            client.messageRepository,
            client.makeMessagesPaginationStateHandler(),
            client.databaseContainer,
            client.apiClient
        )

    /// Used for observing the database for changes.
    private var messagesObserver: ListDatabaseObserverWrapper<ChatMessage, MessageDTO>?

    private func startObserversIfNeeded() {
        guard state == .initialized else { return }
        do {
            try messagesObserver?.startObserving()

            state = .localDataFetched
        } catch {
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
            state = .localDataFetchFailed(ClientError(with: error))
        }
    }

    private func setMessagesObserver() {
        let observer = ListDatabaseObserverWrapper(
            isBackground: StreamRuntimeCheck._isBackgroundMappingEnabled,
            database: client.databaseContainer,
            fetchRequest: MessageDTO.messagesFetchRequest(
                for: lastQuery ?? query
            ),
            itemCreator: { try $0.asModel() as ChatMessage }
        )
        observer.onDidChange = { [weak self] changes in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }
                $0.controller(self, didChangeMessages: changes)
            }
        }

        messagesObserver = observer
    }

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

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<ChatMessageSearchControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)

            // After setting delegate local changes will be fetched and observed.
            startObserversIfNeeded()
        }
    }

    /// Searches messages for the given text.
    ///
    /// When this function is called, `messages` property of this controller will refresh with new messages matching the text.
    /// The delegate function `didChangeMessages` will also be called.
    ///
    /// - Note: Currently, no local data will be searched, only remote data will be queried.
    ///
    /// - Parameters:
    ///   - text: The message text.
    ///   - completion: Called when the controller has finished fetching remote data.
    ///   If the data fetching fails, the error variable contains more details about the problem.
    public func search(text: String, completion: ((_ error: Error?) -> Void)? = nil) {
        startObserversIfNeeded()

        guard let currentUserId = client.currentUserId else {
            completion?(ClientError.CurrentUserDoesNotExist("For message search with text, a current user must be logged in"))
            return
        }

        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let lastQuery = lastQuery {
            messageUpdater.clearSearchResults(for: lastQuery) { error in
                self.nextPageCursor = nil
                self.callback { completion?(error) }
            }
            return
        }

        let query = MessageSearchQuery(
            channelFilter: .containMembers(userIds: [currentUserId]),
            messageFilter: .autocomplete(.text, text: text),
            sort: [.init(key: .createdAt, isAscending: false)]
        )
        
        search(query: query, completion: completion)
    }

    private func resetMessagesObserver() {
        setMessagesObserver()
        state = .initialized
        startObserversIfNeeded()
    }

    /// Searches messages for the given query.
    ///
    /// When this function is called, `messages` property of this
    /// controller will refresh with new messages matching the text.
    ///
    /// The delegate function `didChangeMessages` will also be called.
    ///
    /// - Note: Currently, no local data will be searched, only remote data will be queried.
    ///
    /// - Warning: Make sure the `query` text is not empty. Empty queries will result in 400 errors from backend.
    ///
    /// - Parameters:
    ///   - query: Search query.
    ///   - completion: Called when the controller has finished fetching remote data.
    ///   If the data fetching fails, the error variable contains more details about the problem.
    public func search(query: MessageSearchQuery, completion: ((_ error: Error?) -> Void)? = nil) {
        var query = query
        query.filterHash = explicitFilterHash

        lastQuery = query

        // To respect sorting the user passed, we must reset messagesObserver
        resetMessagesObserver()

        messageUpdater.search(query: query, policy: .replace) { result in
            if case let .success(payload) = result {
                self.updateNextPageCursor(with: payload)
            }

            let error = result.error
            self.state = error == nil ? .remoteDataFetched : .remoteDataFetchFailed(ClientError(with: error))
            self.callback { completion?(error) }
        }
    }

    /// Loads next messages.
    ///
    /// - Parameters:
    ///   - limit: Limit for page size.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    public func loadNextMessages(
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard let lastQuery = lastQuery else {
            completion?(ClientError("You should make a search before calling for next page."))
            return
        }

        var updatedQuery = lastQuery
        if let nextPage = nextPageCursor, !lastQuery.sort.isEmpty {
            updatedQuery.pagination = Pagination(pageSize: limit, cursor: nextPage)
        } else {
            updatedQuery.pagination = Pagination(pageSize: limit, offset: messages.count)
        }

        messageUpdater.search(query: updatedQuery) { result in
            if case let .success(payload) = result {
                self.updateNextPageCursor(with: payload)
            }
            self.callback { completion?(result.error) }
        }
    }

    private func updateNextPageCursor(with payload: MessageSearchResultsPayload) {
        nextPageCursor = payload.next
    }
}

extension ChatMessageSearchController {
    struct Environment {
        var messageUpdaterBuilder: (
            _ isLocalStorageEnabled: Bool,
            _ messageRepository: MessageRepository,
            _ paginationStateHandler: MessagesPaginationStateHandling,
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> MessageUpdater = MessageUpdater.init
    }
}

extension ChatMessageSearchController {
    /// Set the delegate of `ChatMessageSearchController` to observe the changes in the system.
    public weak var delegate: ChatMessageSearchControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }
}

/// `ChatMessageSearchController` uses this protocol to communicate changes to its delegate.
public protocol ChatMessageSearchControllerDelegate: DataControllerStateDelegate {
    /// The controller changed the list of observed messages.
    ///
    /// - Parameters:
    ///   - controller: The controller emitting the change callback.
    ///   - changes: The change to the list of messages.
    func controller(
        _ controller: ChatMessageSearchController,
        didChangeMessages changes: [ListChange<ChatMessage>]
    )
}
