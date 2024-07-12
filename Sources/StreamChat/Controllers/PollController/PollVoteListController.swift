//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

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
}

/// A controller which allows querying and filtering the votes of a poll.
public class PollVoteListController: DataController, DelegateCallable, DataStoreProvider {
    /// The query specifying and filtering the list of users.
    public let query: PollVoteListQuery

    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The votes of the poll the controller represents.
    ///
    /// To observe changes of the votes, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    public var votes: LazyCachedMapCollection<PollVote> {
        startPollVotesListObserverIfNeeded()
        return pollVotesObserver.items
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

            // After setting delegate local changes will be fetched and observed.
            startPollVotesListObserverIfNeeded()
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
                    log.warning("Callback called while self is nil")
                    return
                }

                $0.controller(self, didChangeVotes: changes)
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
    
    private let eventsController: EventsController
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
        eventsController = client.eventsController()
        pollsRepository = client.pollsRepository
        super.init()
        eventsController.delegate = self
    }

    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        startPollVotesListObserverIfNeeded()

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
    /// `pollVotesObserver` to fetch the local data and start observing the changes. It also changes
    /// `state` based on the result.
    private func startPollVotesListObserverIfNeeded() {
        guard state == .initialized else { return }
        do {
            try pollVotesObserver.startObserving()
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
        completion: ((Error?) -> Void)? = nil
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
    }
}

extension PollVoteListController: EventsControllerDelegate {
    public func eventsController(_ controller: EventsController, didReceiveEvent event: any Event) {
        var vote: PollVote?
        if let event = event as? PollVoteCastedEvent {
            vote = event.vote
        } else if let event = event as? PollVoteChangedEvent {
            vote = event.vote
        }
        guard let vote else { return }
        if vote.isAnswer == true && query.pollId == vote.pollId && query.optionId == nil {
            pollsRepository.link(pollVote: vote, to: query)
        }
    }
}
