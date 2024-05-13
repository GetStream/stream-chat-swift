//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
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
    
    public var poll: Poll? {
        startObserversIfNeeded()
        return pollObserver?.item
    }
    
    public var ownVotes: LazyCachedMapCollection<PollVote> {
        ownVotesObserver.items
    }
    
    private let pollsRepository: PollsRepository
    
    /// Set the delegate of `ChannelController` to observe the changes in the system.
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
    
    private var pollObserver: EntityDatabaseObserverWrapper<Poll, PollDTO>?
    
    private(set) lazy var ownVotesObserver: ListDatabaseObserverWrapper<PollVote, PollVoteDTO> = {
        let request = PollVoteDTO.pollVoteListFetchRequest(query: self.ownVotesQuery)

        let observer = environment.ownVotesObserverBuilder(
            StreamRuntimeCheck._isBackgroundMappingEnabled,
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
    @available(iOS 13, *)
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
        
        setupPollObserver()
    }
    
    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        startObserversIfNeeded()

        pollsRepository.queryPollVotes(query: ownVotesQuery) { result in
            if let error = result.error {
                self.state = .remoteDataFetchFailed(ClientError(with: error))
            } else {
                self.state = .remoteDataFetched
            }
            self.callback { completion?(result.error) }
        }
    }
    
    public func castPollVote(
        answerText: String?,
        optionId: String?,
        completion: ((Error?) -> Void)? = nil
    ) {
        pollsRepository.castPollVote(
            messageId: messageId,
            pollId: pollId,
            answerText: answerText,
            optionId: optionId,
            currentUserId: client.currentUserId,
            query: ownVotesQuery,
            completion: completion
        )
    }
    
    public func removePollVote(
        voteId: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        pollsRepository.removePollVote(
            messageId: messageId,
            pollId: pollId,
            voteId: voteId,
            completion: completion
        )
    }
    
    public func closePoll(completion: ((Error?) -> Void)? = nil) {
        pollsRepository.closePoll(pollId: pollId, completion: completion)
    }
    
    public func suggestPollOption(
        text: String,
        position: Int? = nil,
        custom: [String: RawJSON]? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        pollsRepository.suggestPollOption(
            pollId: pollId,
            text: text,
            position: position,
            custom: custom,
            completion: completion
        )
    }
    
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
    
    private func setupPollObserver() {
        pollObserver = { [weak self] in
            guard let self = self else {
                log.warning("Callback called while self is nil")
                return nil
            }
            
            let observer = environment.pollObserverBuilder(
                StreamRuntimeCheck._isBackgroundMappingEnabled,
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
    }
}

public enum VotingVisibility: String {
    case `public`
    case anonymous
}

extension PollController {
    struct Environment {
        var pollObserverBuilder: (
            _ isBackgroundMappingEnabled: Bool,
            _ database: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<PollDTO>,
            _ itemCreator: @escaping (PollDTO) throws -> Poll,
            _ fetchedResultsControllerType: NSFetchedResultsController<PollDTO>.Type
        ) -> EntityDatabaseObserverWrapper<Poll, PollDTO> = {
            EntityDatabaseObserverWrapper(
                isBackground: $0,
                database: $1,
                fetchRequest: $2,
                itemCreator: $3,
                fetchedResultsControllerType: $4
            )
        }
        
        var ownVotesObserverBuilder: (
            _ isBackgroundMappingEnabled: Bool,
            _ database: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<PollVoteDTO>,
            _ itemCreator: @escaping (PollVoteDTO) throws -> PollVote
        ) -> ListDatabaseObserverWrapper<PollVote, PollVoteDTO> = {
            ListDatabaseObserverWrapper(
                isBackground: $0,
                database: $1,
                fetchRequest: $2,
                itemCreator: $3
            )
        }
    }
}
