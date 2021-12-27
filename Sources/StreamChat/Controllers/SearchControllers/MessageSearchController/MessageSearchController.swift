//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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

/// `ChatMessageSearchController` is a controller class which allows paginating messages based on the provided search query.
public class ChatMessageSearchController: DataController, DelegateCallable, DataStoreProvider {
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient
    private let environment: Environment

    init(client: ChatClient, environment: Environment = .init()) {
        self.client = client
        self.environment = environment
        
        super.init()
    }
    
    /// The last search query made, used for getting next page.
    public private(set) var query: MessageSearchQuery?
    
    /// The messages matching the query of this controller.
    ///
    /// To observe changes of the messages, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    private var _messages: [ChatMessage] = []
    public var messageArray: [ChatMessage] {
        setLocalDataFetchedStateIfNeeded()
        return _messages
    }

    lazy var messageUpdater = self.environment
        .messageUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    lazy var basePublishers: BasePublishers = .init(controller: self)

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<ChatMessageSearchControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)

            // After setting delegate local changes will be fetched and observed.
            setLocalDataFetchedStateIfNeeded()
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
    ///   - sorting: Sorting options.
    ///   - completion: Called when the controller has finished fetching remote data.
    ///   If the data fetching fails, the error variable contains more details about the problem.
    public func search(
        text: String,
        sorting: [Sorting<MessageSearchSortingKey>] = [],
        completion: ((_ error: Error?) -> Void)? = nil
    ) {
        guard let currentUserId = client.currentUserId else {
            completion?(ClientError.CurrentUserDoesNotExist("For message search with text, a current user must be logged in"))
            return
        }
        
        let query = MessageSearchQuery(
            channelFilter: .containMembers(userIds: [currentUserId]),
            messageFilter: .queryText(text),
            sort: sorting,
            pageSize: .messagesPageSize
        )
        
        search(query: query, completion: completion)
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
    /// - Parameters:
    ///   - query: Search query.
    ///   - completion: Called when the controller has finished fetching remote data.
    ///   If the data fetching fails, the error variable contains more details about the problem.
    public func search(query: MessageSearchQuery, completion: ((_ error: Error?) -> Void)? = nil) {
        fetch(query, replace: true, completion: completion)
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
        guard var nextPageQuery = query else {
            completion?(ClientError("You should make a search before calling for next page."))
            return
        }

        nextPageQuery.pagination = Pagination(
            pageSize: limit,
            offset: messageArray.count
        )
        
        fetch(nextPageQuery, replace: false, completion: completion)
    }
}

private extension ChatMessageSearchController {
    /// Fetches the given query from the API, updates the list of messages and notifies the delegate.
    ///
    /// - Parameters:
    ///   - query: The query to fetch.
    ///   - completion: The completion that is triggered when the query is processed.
    func fetch(_ query: MessageSearchQuery, replace: Bool, completion: ((Error?) -> Void)? = nil) {
        setLocalDataFetchedStateIfNeeded()
        
        messageUpdater.fetch(query: query) { result in
            switch result {
            case let .success(page):
                self.save(page: page) { loadedMessages in
                    let listChanges = self.prepareListChanges(
                        loadedPage: loadedMessages,
                        replace: replace
                    )
                    
                    self.query = query
                    self._messages = self.messageList(after: listChanges)
                    self.state = .remoteDataFetched
                    
                    self.callback {
                        self.multicastDelegate.invoke { $0.controller(self, didChangeMessages: listChanges) }
                        completion?(nil)
                    }
                }
            case let .failure(error):
                self.state = .remoteDataFetchFailed(ClientError(with: error))
                self.callback { completion?(error) }
            }
        }
    }
    
    /// Saves the given payload to the database and returns database independent models.
    ///
    /// - Parameters:
    ///   - page: The page of users fetched from the API.
    ///   - completion: The completion that will be called with user models when database write is completed.
    func save(page: [MessagePayload], completion: @escaping ([ChatMessage]) -> Void) {
        var loadedMessages: [ChatMessage] = []
        client.databaseContainer.write({ session in
            loadedMessages = page.map { .init(payload: $0, session: session) }
        }, completion: { _ in
            completion(loadedMessages)
        })
    }
    
    /// Creates the list of changes based on current list, the new page, and merge policy.
    ///
    /// - Parameters:
    ///   - loadedPage: The page of messages.
    ///   - replace: The update policy. If `true` the current search results are replaced with the new page.
    /// - Returns: The list of changes that can be applied to the current list of messages.
    func prepareListChanges(loadedPage: [ChatMessage], replace: Bool) -> [ListChange<ChatMessage>] {
        if replace {
            let deletions = messageArray.enumerated().reversed().map { (index, message) in
                ListChange.remove(message, index: .init(row: index, section: 0))
            }
            
            let insertions = messageArray.enumerated().map { (index, message) in
                ListChange.insert(message, index: .init(row: index, section: 0))
            }
            
            return deletions + insertions
        } else {
            let insertions = messageArray.enumerated().map { (index, message) in
                ListChange.insert(message, index: .init(row: index + messageArray.count, section: 0))
            }
            
            return insertions
        }
    }
    
    /// Applies the given changes to the current list of messages and returns the updated list.
    ///
    /// - Parameter changes: The changes to apply.
    /// - Returns: The message list after the given changes applied.
    ///
    func messageList(after changes: [ListChange<ChatMessage>]) -> [ChatMessage] {
        var messages = messageArray
        
        for change in changes {
            switch change {
            case let .insert(message, indexPath):
                messages.insert(message, at: indexPath.row)
            case let .remove(_, indexPath):
                messages.remove(at: indexPath.row)
            default:
                log.assertionFailure("Unsupported list change observed: \(change)")
            }
        }
        
        return messages
    }
    
    /// Sets state to `localDataFetched` if current state is `initialized`.
    ///
    /// Needed to have the same state changes as when search results were saved to database.
    /// Can be removed in v5.
    func setLocalDataFetchedStateIfNeeded() {
        guard state == .initialized else { return }
        
        state = .localDataFetched
    }
}

extension ChatMessageSearchController {
    struct Environment {
        var messageUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> MessageUpdater = MessageUpdater.init

        var createMessageDatabaseObserver: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<MessageDTO>,
            _ itemCreator: @escaping (MessageDTO) -> ChatMessage
        ) -> ListDatabaseObserver<ChatMessage, MessageDTO> = {
            ListDatabaseObserver(context: $0, fetchRequest: $1, itemCreator: $2)
        }
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
