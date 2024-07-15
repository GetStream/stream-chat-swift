//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// `ChatThreadListController` uses this protocol to communicate changes to its delegate.
public protocol ChatThreadListControllerDelegate: DataControllerStateDelegate {
    /// The controller changed the list of observed threads.
    ///
    /// - Parameters:
    ///   - controller: The controller emitting the change callback.
    ///   - changes: The change to the list of threads.
    func controller(
        _ controller: ChatThreadListController,
        didChangeThreads changes: [ListChange<ChatThread>]
    )
}

/// `ChatThreadListController` is a controller class which allows querying and
/// observing the threads that the current user is participating.
public class ChatThreadListController: DataController, DelegateCallable, DataStoreProvider {
    /// The query of the thread list.
    public let query: ThreadListQuery

    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The cursor of the next page in case there is more data.
    private var nextCursor: String?

    /// The threads matching the query of this controller.
    ///
    /// To observe changes of the threads, set your class as a delegate of this controller
    /// or use the provided combine publishers.
    public var threads: LazyCachedMapCollection<ChatThread> {
        startThreadListObserverIfNeeded()
        return threadListObserver.items
    }

    /// The repository used to fetch the data from remote and local cache.
    private lazy var threadsRepository: ThreadsRepository = self.environment
        .threadsRepositoryBuilder(
            client.databaseContainer,
            client.apiClient
        )

    /// A Boolean value that returns whether pagination is finished.
    public private(set) var hasLoadedAllThreads: Bool = false

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<ChatThreadListControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)

            // After setting delegate local changes will be fetched and observed.
            startThreadListObserverIfNeeded()
        }
    }

    private(set) lazy var threadListObserver: BackgroundListDatabaseObserver<ChatThread, ThreadDTO> = {
        let request = ThreadDTO.threadListFetchRequest()
        let observer = self.environment.createThreadListDatabaseObserver(
            client.databaseContainer,
            request,
            { try $0.asModel() }
        )

        observer.onDidChange = { [weak self] changes in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    return
                }
                $0.controller(self, didChangeThreads: changes)
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

    /// Creates a new `ChatThreadListController`.
    init(
        query: ThreadListQuery,
        client: ChatClient,
        environment: Environment = .init()
    ) {
        self.client = client
        self.query = query
        self.environment = environment
    }

    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        startThreadListObserverIfNeeded()
        threadsRepository.loadThreads(
            query: query
        ) { [weak self] result in
            switch result {
            case let .success(threadListResponse):
                self?.callback {
                    self?.state = .remoteDataFetched
                    self?.nextCursor = threadListResponse.next
                    self?.hasLoadedAllThreads = threadListResponse.next == nil
                    completion?(nil)
                }
            case let .failure(error):
                self?.state = .remoteDataFetchFailed(ClientError(with: error))
                self?.callback { completion?(error) }
            }
        }
    }

    // MARK: - Actions

    /// Loads more threads.
    ///
    /// - Parameters:
    ///   - limit: The size of the new page of threads.
    ///   - completion: The completion.
    public func loadMoreThreads(
        limit: Int? = nil,
        completion: ((Result<[ChatThread], Error>) -> Void)? = nil
    ) {
        let limit = limit ?? query.limit
        var updatedQuery = query
        updatedQuery.limit = limit
        updatedQuery.next = nextCursor
        threadsRepository.loadThreads(query: updatedQuery) { [weak self] result in
            switch result {
            case let .success(threadListResponse):
                self?.callback {
                    let threads = threadListResponse.threads
                    self?.nextCursor = threadListResponse.next
                    self?.hasLoadedAllThreads = threadListResponse.next == nil
                    completion?(.success(threads))
                }
            case let .failure(error):
                self?.callback {
                    completion?(.failure(error))
                }
            }
        }
    }

    // MARK: - Helpers

    /// If the `state` of the controller is `initialized`, this method calls `startObserving` on the
    /// `threadListObserver` to fetch the local data and start observing the changes. It also changes
    /// `state` based on the result.
    private func startThreadListObserverIfNeeded() {
        guard state == .initialized else { return }
        do {
            try threadListObserver.startObserving()
            state = .localDataFetched
        } catch {
            state = .localDataFetchFailed(ClientError(with: error))
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
        }
    }
}

extension ChatThreadListController {
    /// Set the delegate of `ThreadListController` to observe thread changes.
    public weak var delegate: ChatThreadListControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }
}

extension ChatThreadListController {
    struct Environment {
        var threadsRepositoryBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ThreadsRepository = ThreadsRepository.init

        var createThreadListDatabaseObserver: (
            _ database: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<ThreadDTO>,
            _ itemCreator: @escaping (ThreadDTO) throws -> ChatThread
        )
            -> BackgroundListDatabaseObserver<ChatThread, ThreadDTO> = {
                BackgroundListDatabaseObserver(
                    database: $0,
                    fetchRequest: $1,
                    itemCreator: $2,
                    itemReuseKeyPaths: (\ChatThread.reuseId, \ThreadDTO.reuseId)
                )
            }
    }
}
