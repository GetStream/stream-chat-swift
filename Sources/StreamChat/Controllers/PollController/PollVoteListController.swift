//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
import Foundation

public extension ChatClient {
    /// Creates and returns a `PollVoteListController` for the specified query.
    ///
    /// - Parameter query: The query object defining the criteria for retrieving the list of poll votes.
    /// - Returns: A `PollVoteListController` initialized with the provided query and client.
    func pollVoteListController(query: PollVoteListQuery) -> PollVoteListController {
        .init(query: query, client: self)
    }
}

/// `PollVoteListController` uses this protocol to communicate changes to its delegate.
public protocol PollVoteListControllerDelegate: DataControllerStateDelegate {
    /// The controller changed the list of observed votes.
    ///
    /// - Parameters:
    ///   - controller: The controller emitting the change callback.
    ///   - changes: The change to the list of votes.
    func controller(
        _ controller: PollVoteListController,
        didChangeVotes changes: [ListChange<PollVote>]
    )
    
    /// The controller updated the poll.
    ///
    /// - Parameters:
    ///   - controller: The controller emitting the change callback.
    ///   - poll: The poll with the new data.
    func controller(
        _ controller: PollVoteListController,
        didUpdatePoll poll: Poll
    )
}

/// Optional delegate methods.
public extension PollVoteListControllerDelegate {
    func controller(
        _ controller: PollVoteListController,
        didUpdatePoll poll: Poll
    ) {}
}

/// A controller which allows querying and filtering the votes of a poll.
public class PollVoteListController: DataController, DelegateCallable, DataStoreProvider, @unchecked Sendable {
    /// The query specifying and filtering the list of users.
    public let query: PollVoteListQuery

    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The votes of the poll the controller represents.
    public var votes: [PollVote] {
        startObserversIfNeeded()
        return pollVotesObserver.items
    }
    
    /// Returns the poll that this controller represents.
    public var poll: Poll? {
        startObserversIfNeeded()
        return pollObserver?.item
    }
    
    /// A Boolean value that returns whether pagination is finished.
    public private(set) var hasLoadedAllVotes: Bool = false

    /// Set the delegate of `PollVoteListController` to observe the changes in the system.
    public weak var delegate: PollVoteListControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<PollVoteListControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)
            startObserversIfNeeded()
        }
    }

    /// Used for observing the database for changes.
    private(set) lazy var pollVotesObserver: BackgroundListDatabaseObserver<PollVote, PollVoteDTO> = {
        let request = PollVoteDTO.pollVoteListFetchRequest(query: query)

        let observer = self.environment.createPollListDatabaseObserver(
            client.databaseContainer,
            request,
            { try $0.asModel() }
        )

        observer.onDidChange = { [weak self] changes in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    return
                }

                $0.controller(self, didChangeVotes: changes)
            }
        }

        return observer
    }()

    /// Used for observing the poll for changes.
    private lazy var pollObserver: BackgroundEntityDatabaseObserver<Poll, PollDTO>? = { [weak self] in
        guard let self = self else {
            return nil
        }
        
        let observer = environment.pollObserverBuilder(
            self.client.databaseContainer,
            PollDTO.fetchRequest(for: query.pollId),
            { try $0.asModel() as Poll },
            NSFetchedResultsController<PollDTO>.self
        )
        .onChange { [weak self] change in
            self?.delegateCallback { [weak self] delegate in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }
                delegate.controller(self, didUpdatePoll: change.item)
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
    
    private var eventsObserver: AnyCancellable?
    private let pollsRepository: PollsRepository
    private let environment: Environment
    private var nextCursor: String?

    /// Creates a new `PollVoteListController`.
    ///
    /// - Parameters:
    ///   - query: The query used for filtering the votes.
    ///   - client: The `Client` instance this controller belongs to.
    init(query: PollVoteListQuery, client: ChatClient, environment: Environment = .init()) {
        self.client = client
        self.query = query
        self.environment = environment
        pollsRepository = client.pollsRepository
        super.init()
        eventsObserver = client.subscribe { [weak self] event in
            guard let self else { return }
            self.didReceiveEvent(event)
        }
    }
    
    func didReceiveEvent(_ event: Event) {
        var vote: PollVote?
        if let event = event as? PollVoteCastedEvent {
            vote = event.vote
        } else if let event = event as? PollVoteChangedEvent {
            vote = event.vote
        }
        guard let vote else { return }
        if vote.isAnswer == true
            && query.pollId == vote.pollId
            && query.optionId == nil {
            pollsRepository.link(pollVote: vote, to: query)
        } else if vote.isAnswer == false
            && query.pollId == vote.pollId
            && query.optionId == vote.optionId {
            pollsRepository.link(pollVote: vote, to: query)
        }
    }

    override public func synchronize(_ completion: (@MainActor (_ error: Error?) -> Void)? = nil) {
        startObserversIfNeeded()

        pollsRepository.queryPollVotes(query: query) { [weak self] result in
            guard let self else { return }
            if let value = result.value {
                self.nextCursor = value.next
                self.hasLoadedAllVotes = value.next == nil
            }
            if let error = result.error {
                self.state = .remoteDataFetchFailed(ClientError(with: error))
            } else {
                self.state = .remoteDataFetched
            }
            self.callback { completion?(result.error) }
        }
    }

    /// If the `state` of the controller is `initialized`, this method calls `startObserving` on the
    /// `pollVotesObserver` and `pollObserver` to fetch the local data and start observing the changes. It also changes
    /// `state` based on the result.
    private func startObserversIfNeeded() {
        guard state == .initialized else { return }
        do {
            try pollVotesObserver.startObserving()
            try pollObserver?.startObserving()
            state = .localDataFetched
        } catch {
            state = .localDataFetchFailed(ClientError(with: error))
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
        }
    }

    // MARK: - Actions

    /// Loads more votes.
    ///
    /// - Parameters:
    ///   - limit: Limit for the page size.
    ///   - completion: The completion callback.
    public func loadMoreVotes(
        limit: Int? = nil,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        let limit = limit ?? query.pagination.pageSize
        var updatedQuery = query
        updatedQuery.pagination = Pagination(pageSize: limit, cursor: nextCursor)
        pollsRepository.queryPollVotes(query: updatedQuery) { [weak self] result in
            guard let self else { return }
            if let value = result.value {
                self.nextCursor = value.next
                self.hasLoadedAllVotes = value.next == nil
            }
            self.callback { completion?(result.error) }
        }
    }
}

extension PollVoteListController {
    struct Environment {
        var pollsRepositoryBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> PollsRepository = PollsRepository.init

        var createPollListDatabaseObserver: (
            _ database: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<PollVoteDTO>,
            _ itemCreator: @escaping (PollVoteDTO) throws -> PollVote
        )
            -> BackgroundListDatabaseObserver<PollVote, PollVoteDTO> = {
                BackgroundListDatabaseObserver(
                    database: $0,
                    fetchRequest: $1,
                    itemCreator: $2,
                    itemReuseKeyPaths: (\PollVote.id, \PollVoteDTO.id)
                )
            }
        
        var pollObserverBuilder: (
            _ database: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<PollDTO>,
            _ itemCreator: @escaping (PollDTO) throws -> Poll,
            _ fetchedResultsControllerType: NSFetchedResultsController<PollDTO>.Type
        ) -> BackgroundEntityDatabaseObserver<Poll, PollDTO> = {
            BackgroundEntityDatabaseObserver(
                database: $0,
                fetchRequest: $1,
                itemCreator: $2,
                fetchedResultsControllerType: $3
            )
        }
    }
}
