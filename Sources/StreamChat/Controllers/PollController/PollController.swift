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
    
    private var pollObserver: EntityDatabaseObserverWrapper<Poll, PollDTO>?
    
    // TODO: environment
    // TODO: reuse poll repository
    init(client: ChatClient, messageId: MessageId, pollId: String) {
        self.client = client
        self.messageId = messageId
        self.pollId = pollId
        pollsRepository = PollsRepository(
            database: client.databaseContainer,
            apiClient: client.apiClient
        )
        
        super.init()
        
        setupPollObserver()
    }
    
    public func castPollVote(
        messageId: MessageId,
        pollId: String,
        answerText: String?,
        optionId: String?,
        completion: ((Error?) -> Void)? = nil
    ) {
        pollsRepository.castPollVote(
            messageId: messageId,
            pollId: pollId,
            answerText: answerText,
            optionId: optionId,
            completion: completion
        )
    }
    
    public func removePollVote(
        messageId: MessageId,
        pollId: String,
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
                self?.delegateCallback { [weak self] in
                    guard let self = self else {
                        log.warning("Callback called while self is nil")
                        return
                    }
                    $0.pollController(self, didUpdatePoll: change)
                }
            }

            return observer
        }()
        try? pollObserver?.startObserving()
    }
}
