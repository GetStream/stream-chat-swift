//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
    /// Creates and returns a `PollController` for the specified message and poll.
    ///
    /// - Parameters:
    ///   - messageId: The unique identifier of the message associated with the poll.
    ///   - pollId: The unique identifier of the poll.
    /// - Returns: A `PollController` initialized with the provided client, message ID, and poll ID.
    func pollController(messageId: MessageId, pollId: String) -> PollController {
        .init(client: self, messageId: messageId, pollId: pollId)
    }
}

public class PollController: DataController, DelegateCallable, DataStoreProvider {
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The identifier of the message the poll belongs to.
    public let messageId: MessageId

    /// The identifier of the poll this controllers represents.
    public let pollId: String
    
    /// Returns the poll that this controllers represents.
    public var poll: Poll? {
        startObserversIfNeeded()
        return pollObserver?.item
    }
    
    /// Returns the current user's votes.
    public var ownVotes: LazyCachedMapCollection<PollVote> {
        ownVotesObserver.items
    }
    
    private let pollsRepository: PollsRepository
    
    /// Set the delegate of `PollController` to observe the changes in the system.
    public var delegate: PollControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }

    /// A type-erased delegate.
    internal var multicastDelegate: MulticastDelegate<PollControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)
        }
    }
    
    let ownVotesQuery: PollVoteListQuery
    
    private let eventsController: EventsController
    
    private lazy var pollObserver: BackgroundEntityDatabaseObserver<Poll, PollDTO>? = { [weak self] in
        guard let self = self else {
            log.warning("Callback called while self is nil")
            return nil
        }
        
        let observer = environment.pollObserverBuilder(
            self.client.databaseContainer,
            PollDTO.fetchRequest(for: pollId),
            { try $0.asModel() as Poll },
            NSFetchedResultsController<PollDTO>.self
        )
        .onChange { [weak self] change in
            self?.delegateCallback { [weak self] delegate in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }
                delegate.pollController(self, didUpdatePoll: change)
            }
        }

        return observer
    }()
    
    private(set) lazy var ownVotesObserver: BackgroundListDatabaseObserver<PollVote, PollVoteDTO> = {
        let request = PollVoteDTO.pollVoteListFetchRequest(query: self.ownVotesQuery)

        let observer = environment.ownVotesObserverBuilder(
            self.client.databaseContainer,
            request,
            { try $0.asModel() }
        )
        
        observer.onDidChange = { [weak self] changes in
            self?.delegateCallback { [weak self] delegate in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }

                delegate.pollController(self, didUpdateCurrentUserVotes: changes)
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
        
    init(client: ChatClient, messageId: MessageId, pollId: String, environment: Environment = .init()) {
        self.client = client
        self.messageId = messageId
        self.pollId = pollId
        self.environment = environment
        eventsController = client.eventsController()
        ownVotesQuery = PollVoteListQuery(
            pollId: pollId,
            optionId: nil,
            pagination: .init(pageSize: 25, cursor: nil),
            filter: .and(
                [.equal(.userId, to: client.currentUserId ?? ""), .equal(.pollId, to: pollId)]
            )
        )
        pollsRepository = client.pollsRepository
        super.init()
        eventsController.delegate = self
    }
    
    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        startObserversIfNeeded()

        pollsRepository.queryPollVotes(query: ownVotesQuery) { [weak self] result in
            guard let self else { return }
            if let error = result.error {
                self.state = .remoteDataFetchFailed(ClientError(with: error))
            } else {
                self.state = .remoteDataFetched
            }
            self.callback { completion?(result.error) }
        }
    }
    
    /// Casts a vote for a poll.
    ///
    /// - Parameters:
    ///   - answerText: An optional text answer for the poll.
    ///   - optionId: An optional identifier for the poll option.
    ///   - completion: A closure to be called upon completion, with an optional `Error` if something went wrong.
    public func castPollVote(
        answerText: String?,
        optionId: String?,
        completion: ((Error?) -> Void)? = nil
    ) {
        if answerText == nil && optionId == nil {
            completion?(ClientError.InvalidInput())
            return
        }
        
        var deleteExistingVotes = [PollVote]()
        if poll?.enforceUniqueVote == true && !ownVotes.isEmpty {
            if optionId != nil {
                deleteExistingVotes = Array(ownVotes.filter { !$0.isAnswer })
            } else {
                deleteExistingVotes = Array(ownVotes.filter { $0.isAnswer })
            }
        }
        
        pollsRepository.castPollVote(
            messageId: messageId,
            pollId: pollId,
            answerText: answerText,
            optionId: optionId,
            currentUserId: client.currentUserId,
            query: ownVotesQuery,
            deleteExistingVotes: deleteExistingVotes,
            completion: { [weak self] result in
                self?.callback {
                    completion?(result)
                }
            }
        )
    }

    /// Removes a vote from a poll.
    ///
    /// - Parameters:
    ///   - voteId: The identifier of the vote to be removed.
    ///   - completion: A closure to be called upon completion, with an optional `Error` if something went wrong.
    public func removePollVote(
        voteId: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        pollsRepository.removePollVote(
            messageId: messageId,
            pollId: pollId,
            voteId: voteId,
            completion: { [weak self] result in
                self?.callback {
                    completion?(result)
                }
            }
        )
    }

    /// Closes the poll.
    ///
    /// - Parameters:
    ///   - completion: A closure to be called upon completion, with an optional `Error` if something went wrong.
    public func closePoll(completion: ((Error?) -> Void)? = nil) {
        pollsRepository.closePoll(pollId: pollId, completion: { [weak self] result in
            self?.callback {
                completion?(result)
            }
        })
    }

    /// Suggests a new option for the poll.
    ///
    /// - Parameters:
    ///   - text: The text of the suggested poll option.
    ///   - position: An optional position for the suggested option.
    ///   - custom: An optional dictionary of custom data for the suggested option.
    ///   - completion: A closure to be called upon completion, with an optional `Error` if something went wrong.
    public func suggestPollOption(
        text: String,
        position: Int? = nil,
        extraData: [String: RawJSON]? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        pollsRepository.suggestPollOption(
            pollId: pollId,
            text: text,
            position: position,
            custom: extraData,
            completion: { [weak self] result in
                self?.callback {
                    completion?(result)
                }
            }
        )
    }
    
    // MARK: - private
    
    private func startObserversIfNeeded() {
        guard state == .initialized else { return }
        do {
            try pollObserver?.startObserving()
            try ownVotesObserver.startObserving()
            state = .localDataFetched
        } catch {
            state = .localDataFetchFailed(ClientError(with: error))
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
        }
    }
}

/// Represents the visibility of votes in a poll.
public struct VotingVisibility: RawRepresentable, Equatable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    /// Votes are public and can be seen by everyone.
    public static let `public` = Self(rawValue: "public")
    /// Votes are anonymous and cannot be attributed to individual users.
    public static let anonymous = Self(rawValue: "anonymous")
}

extension PollController {
    struct Environment {
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
        
        var ownVotesObserverBuilder: (
            _ database: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<PollVoteDTO>,
            _ itemCreator: @escaping (PollVoteDTO) throws -> PollVote
        ) -> BackgroundListDatabaseObserver<PollVote, PollVoteDTO> = {
            BackgroundListDatabaseObserver(
                database: $0,
                fetchRequest: $1,
                itemCreator: $2,
                itemReuseKeyPaths: (\PollVote.id, \PollVoteDTO.id)
            )
        }
    }
}

extension PollController: EventsControllerDelegate {
    public func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        if let event = event as? PollVoteChangedEvent {
            let vote = event.vote
            if vote.user?.id == client.currentUserId {
                pollsRepository.link(pollVote: vote, to: ownVotesQuery)
            }
        }
    }
}
