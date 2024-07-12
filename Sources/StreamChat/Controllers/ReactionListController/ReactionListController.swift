//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// `ChatReactionListController` uses this protocol to communicate changes to its delegate.
public protocol ChatReactionListControllerDelegate: DataControllerStateDelegate {
    /// The controller changed the list of observed reactions.
    ///
    /// - Parameters:
    ///   - controller: The controller emitting the change callback.
    ///   - changes: The change to the list of reactions.
    func controller(
        _ controller: ChatReactionListController,
        didChangeReactions changes: [ListChange<ChatMessageReaction>]
    )
}

/// A controller which allows querying and filtering the reactions of a message.
public class ChatReactionListController: DataController, DelegateCallable, DataStoreProvider {
    /// The query specifying and filtering the list of reactions.
    public let query: ReactionListQuery

    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The total reactions of the message the controller represents.
    ///
    /// To observe changes of the reactions, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    public var reactions: LazyCachedMapCollection<ChatMessageReaction> {
        startReactionListObserverIfNeeded()
        return reactionListObserver.items
    }

    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var worker: ReactionListUpdater = self.environment
        .reactionListQueryUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )

    /// Set the delegate of `ReactionListController` to observe the changes in the system.
    public weak var delegate: ChatReactionListControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<ChatReactionListControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)

            // After setting delegate local changes will be fetched and observed.
            startReactionListObserverIfNeeded()
        }
    }

    /// Used for observing the database for changes.
    private(set) lazy var reactionListObserver: BackgroundListDatabaseObserver<ChatMessageReaction, MessageReactionDTO> = {
        let request = MessageReactionDTO.reactionListFetchRequest(query: query)

        let observer = self.environment.createReactionListDatabaseObserver(
            client.databaseContainer,
            request,
            { try $0.asModel() }
        )

        observer.onDidChange = { [weak self] changes in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }

                $0.controller(self, didChangeReactions: changes)
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

    private let environment: Environment

    /// Creates a new `ChatReactionListController`.
    ///
    /// - Parameters:
    ///   - query: The query used for filtering the reactions.
    ///   - client: The `Client` instance this controller belongs to.
    init(query: ReactionListQuery, client: ChatClient, environment: Environment = .init()) {
        self.client = client
        self.query = query
        self.environment = environment
    }

    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        startReactionListObserverIfNeeded()

        worker.loadReactions(query: query) { result in
            if let error = result.error {
                self.state = .remoteDataFetchFailed(ClientError(with: error))
            } else {
                self.state = .remoteDataFetched
            }
            self.callback { completion?(result.error) }
        }
    }

    /// If the `state` of the controller is `initialized`, this method calls `startObserving` on the
    /// `reactionListObserver` to fetch the local data and start observing the changes. It also changes
    /// `state` based on the result.
    private func startReactionListObserverIfNeeded() {
        guard state == .initialized else { return }
        do {
            try reactionListObserver.startObserving()
            state = .localDataFetched
        } catch {
            state = .localDataFetchFailed(ClientError(with: error))
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
        }
    }
}

// MARK: - Actions

public extension ChatReactionListController {
    /// Loads more reactions.
    ///
    /// - Parameters:
    ///   - limit: Limit for the page size.
    ///   - completion: The completion callback.
    func loadMoreReactions(
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) {
        var updatedQuery = query
        updatedQuery.pagination = Pagination(pageSize: limit, offset: reactions.count)
        worker.loadReactions(query: updatedQuery) { result in
            self.callback { completion?(result.error) }
        }
    }
}

extension ChatReactionListController {
    struct Environment {
        var reactionListQueryUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ReactionListUpdater = ReactionListUpdater.init

        var createReactionListDatabaseObserver: (
            _ database: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<MessageReactionDTO>,
            _ itemCreator: @escaping (MessageReactionDTO) throws -> ChatMessageReaction
        )
            -> BackgroundListDatabaseObserver<ChatMessageReaction, MessageReactionDTO> = {
                BackgroundListDatabaseObserver(
                    database: $0,
                    fetchRequest: $1,
                    itemCreator: $2,
                    itemReuseKeyPaths: (\ChatMessageReaction.id, \MessageReactionDTO.id)
                )
            }
    }
}
