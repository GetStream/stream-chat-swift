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
    
    private let ownVotesQuery: PollVoteListQuery
    
    private var pollObserver: EntityDatabaseObserverWrapper<Poll, PollDTO>?
    
    private(set) lazy var ownVotesObserver: ListDatabaseObserverWrapper<PollVote, PollVoteDTO> = {
        let request = PollVoteDTO.pollVoteListFetchRequest(query: self.ownVotesQuery)

        // TODO: environment
        let observer = ListDatabaseObserverWrapper(
            isBackground: StreamRuntimeCheck._isBackgroundMappingEnabled,
            database: self.client.databaseContainer,
            fetchRequest: request,
            itemCreator: { try $0.asModel() }
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
        
    // TODO: environment
    // TODO: reuse poll repository
    init(client: ChatClient, messageId: MessageId, pollId: String) {
        self.client = client
        self.messageId = messageId
        self.pollId = pollId
        ownVotesQuery = PollVoteListQuery(
            pollId: pollId,
            optionId: nil,
            pagination: .init(pageSize: 25, cursor: nil),
            filter: .and(
                [.equal(.userId, to: client.currentUserId ?? ""), .equal(.pollId, to: pollId)]
            )
        )
        pollsRepository = PollsRepository(
            database: client.databaseContainer,
            apiClient: client.apiClient
        )
        
        super.init()
        
        setupPollObserver()
        try? ownVotesObserver.startObserving()
    }
    
    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
//        startPollVotesListObserverIfNeeded()

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
        guard let currentUserId = client.currentUserId else {
            completion?(ClientError.CurrentUserDoesNotExist())
            return
        }
        pollsRepository.castPollVote(
            messageId: messageId,
            pollId: pollId,
            answerText: answerText,
            optionId: optionId,
            currentUserId: currentUserId,
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
    
    private func setupPollObserver() {
        pollObserver = { [weak self] in
            guard let self = self else {
                log.warning("Callback called while self is nil")
                return nil
            }
            
            let observer = EntityDatabaseObserverWrapper(
                isBackground: StreamRuntimeCheck._isBackgroundMappingEnabled,
                database: self.client.databaseContainer,
                fetchRequest: PollDTO.fetchRequest(for: pollId),
                itemCreator: { try $0.asModel() as Poll },
                fetchedResultsControllerType: NSFetchedResultsController<PollDTO>.self
            ).onChange { [weak self] change in
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
        try? pollObserver?.startObserving()
    }
}
