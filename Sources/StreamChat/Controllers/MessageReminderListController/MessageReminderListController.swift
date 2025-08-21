//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
    /// Creates and returns a `MessageReminderListController` for the specified query.
    ///
    /// - Parameter query: The query object defining the criteria for retrieving the list of message reminders.
    /// - Returns: A `MessageReminderListController` initialized with the provided query and client.
    func messageReminderListController(query: MessageReminderListQuery = .init()) -> MessageReminderListController {
        .init(query: query, client: self)
    }
}

/// `MessageReminderListController` uses this protocol to communicate changes to its delegate.
public protocol MessageReminderListControllerDelegate: DataControllerStateDelegate {
    /// The controller changed the list of observed reminders.
    ///
    /// - Parameters:
    ///   - controller: The controller emitting the change callback.
    ///   - changes: The change to the list of reminders.
    func controller(
        _ controller: MessageReminderListController,
        didChangeReminders changes: [ListChange<MessageReminder>]
    )
}

/// A controller which allows querying and filtering message reminders.
public class MessageReminderListController: DataController, DelegateCallable, DataStoreProvider, @unchecked Sendable {
    /// The query specifying and filtering the list of reminders.
    public let query: MessageReminderListQuery

    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The message reminders the controller represents.
    ///
    /// To observe changes of the reminders, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    public var reminders: LazyCachedMapCollection<MessageReminder> {
        startMessageRemindersObserverIfNeeded()
        return messageRemindersObserver.items
    }
    
    /// A Boolean value that returns whether pagination is finished.
    public private(set) var hasLoadedAllReminders: Bool = false

    /// Set the delegate of `MessageReminderListController` to observe the changes in the system.
    public weak var delegate: MessageReminderListControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<MessageReminderListControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)

            // After setting delegate local changes will be fetched and observed.
            startMessageRemindersObserverIfNeeded()
        }
    }

    /// Used for observing the database for changes.
    private(set) lazy var messageRemindersObserver: BackgroundListDatabaseObserver<MessageReminder, MessageReminderDTO> = {
        let request = MessageReminderDTO.remindersFetchRequest(query: query)

        let observer = self.environment.createMessageReminderListDatabaseObserver(
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

                $0.controller(self, didChangeReminders: changes)
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
    
    private let remindersRepository: RemindersRepository
    private let environment: Environment
    private var nextCursor: String?

    /// Creates a new `MessageReminderListController`.
    ///
    /// - Parameters:
    ///   - query: The query used for filtering the reminders.
    ///   - client: The `Client` instance this controller belongs to.
    init(query: MessageReminderListQuery, client: ChatClient, environment: Environment = .init()) {
        self.client = client
        self.query = query
        self.environment = environment
        remindersRepository = client.remindersRepository
        super.init()
    }

    override public func synchronize(_ completion: (@MainActor(_ error: Error?) -> Void)? = nil) {
        startMessageRemindersObserverIfNeeded()

        remindersRepository.loadReminders(query: query) { [weak self] result in
            guard let self else { return }
            if let value = result.value {
                self.nextCursor = value.next
                self.hasLoadedAllReminders = value.next == nil
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
    /// `messageRemindersObserver` to fetch the local data and start observing the changes. It also changes
    /// `state` based on the result.
    private func startMessageRemindersObserverIfNeeded() {
        guard state == .initialized else { return }
        do {
            try messageRemindersObserver.startObserving()
            state = .localDataFetched
        } catch {
            state = .localDataFetchFailed(ClientError(with: error))
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
        }
    }

    // MARK: - Actions

    /// Loads more reminders.
    ///
    /// - Parameters:
    ///   - limit: Limit for the page size.
    ///   - completion: The completion callback.
    public func loadMoreReminders(
        limit: Int? = nil,
        completion: (@MainActor(Result<[MessageReminder], Error>) -> Void)? = nil
    ) {
        let limit = limit ?? query.pagination.pageSize
        var updatedQuery = query
        updatedQuery.pagination = Pagination(pageSize: limit, cursor: nextCursor)
        remindersRepository.loadReminders(query: updatedQuery) { [weak self] result in
            switch result {
            case let .success(value):
                self?.callback { [weak self] in
                    self?.nextCursor = value.next
                    self?.hasLoadedAllReminders = value.next == nil
                    completion?(.success(value.reminders))
                }
            case let .failure(error):
                self?.callback {
                    completion?(.failure(error))
                }
            }
        }
    }
}

extension MessageReminderListController {
    struct Environment {
        var createMessageReminderListDatabaseObserver: (
            _ database: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<MessageReminderDTO>,
            _ itemCreator: @escaping (MessageReminderDTO) throws -> MessageReminder
        )
            -> BackgroundListDatabaseObserver<MessageReminder, MessageReminderDTO> = {
                BackgroundListDatabaseObserver(
                    database: $0,
                    fetchRequest: $1,
                    itemCreator: $2,
                    itemReuseKeyPaths: (\MessageReminder.id, \MessageReminderDTO.id)
                )
            }
    }
}
