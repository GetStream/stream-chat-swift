//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
    /// Creates a new `MessageSearchController` with the provided user query.
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
    }

    /// Filter hash this controller observes.
    let explicitFilterHash = UUID().uuidString

    lazy var query: MessageSearchQuery = {
        // Filter is just a mock, explicit hash will override it
        var messageFilter = Filter<MessageSearchFilterScope>.exists(.text)
        messageFilter.explicitHash = explicitFilterHash

        return MessageSearchQuery(messageFilter: messageFilter)
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
            client.databaseContainer,
            client.apiClient
        )
    
    /// Used for observing the database for changes.
    lazy var messagesObserver: ListDatabaseObserver<ChatMessage, MessageDTO>? = {
        // TODO:
        nil
    }()
    
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

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<AnyMessageSearchControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.mainDelegate = multicastDelegate.mainDelegate
            stateMulticastDelegate.additionalDelegates = multicastDelegate.additionalDelegates

            // After setting delegate local changes will be fetched and observed.
            startObserversIfNeeded()
        }
    }

    /// Sets the provided object as a delegate of this controller.
    ///
    /// - Parameter delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object
    /// alive if you want keep receiving updates.
    public func setDelegate<Delegate: ChatMessageSearchControllerDelegate>(_ delegate: Delegate) {
        multicastDelegate.mainDelegate = AnyMessageSearchControllerDelegate(delegate)
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
        let query = MessageSearchQuery(messageFilter: .contains(.text, value: text))
        lastQuery = query
        messageUpdater.search(query: query) { [weak self] error in
            self?.state = error == nil ? .remoteDataFetched : .remoteDataFetchFailed(ClientError(with: error))
            self?.callback { completion?(error) }
        }
    }

    /// Searches users for the given query.
    ///
    /// When this function is called, `messages` property of this controller will refresh with new users matching the term.
    /// The delegate function `didChangeMessages` will also be called.
    ///
    /// - Note: Currently, no local data will be searched, only remote data will be queried.
    ///
    /// - Parameters:
    ///   - query: Search query.
    ///   - completion: Called when the controller has finished fetching remote data.
    ///   If the data fetching fails, the error variable contains more details about the problem.
    public func search(query: MessageSearchQuery, completion: ((_ error: Error?) -> Void)? = nil) {
        startObserversIfNeeded()

        lastQuery = query
        messageUpdater.search(query: query) { error in
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
        updatedQuery.pagination = Pagination(pageSize: limit, offset: messages.count)
        messageUpdater.search(query: updatedQuery) { error in
            self.callback { completion?(error) }
        }
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
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? ChatMessageSearchControllerDelegate }
        set { multicastDelegate.mainDelegate = AnyMessageSearchControllerDelegate(newValue) }
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

// MARK: - Delegate type eraser

class AnyMessageSearchControllerDelegate: ChatMessageSearchControllerDelegate {
    private var _controllerDidChangeMessages: (ChatMessageSearchController, [ListChange<ChatMessage>])
        -> Void
    private var _controllerDidChangeState: (DataController, DataController.State) -> Void

    weak var wrappedDelegate: AnyObject?

    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (DataController, DataController.State) -> Void,
        controllerDidChangeMessages: @escaping (ChatMessageSearchController, [ListChange<ChatMessage>])
            -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeState = controllerDidChangeState
        _controllerDidChangeMessages = controllerDidChangeMessages
    }

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        _controllerDidChangeState(controller, state)
    }

    func controller(
        _ controller: ChatMessageSearchController,
        didChangeMessages changes: [ListChange<ChatMessage>]
    ) {
        _controllerDidChangeMessages(controller, changes)
    }
}

extension AnyMessageSearchControllerDelegate {
    convenience init<Delegate: ChatMessageSearchControllerDelegate>(_ delegate: Delegate) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidChangeMessages: { [weak delegate] in delegate?.controller($0, didChangeMessages: $1) }
        )
    }
}

extension AnyMessageSearchControllerDelegate {
    convenience init(_ delegate: ChatMessageSearchControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidChangeMessages: { [weak delegate] in delegate?.controller($0, didChangeMessages: $1) }
        )
    }
}
