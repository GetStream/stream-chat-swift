//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
    /// Creates and returns a `ScheduledMessageListController` for the specified query.
    ///
    /// - Parameter query: The query defining which of the current user's scheduled messages to list.
    func scheduledMessageListController(query: ScheduledMessageListQuery = .init()) -> ScheduledMessageListController {
        .init(query: query, client: self)
    }
}

/// `ScheduledMessageListController` uses this protocol to communicate changes to its delegate.
public protocol ScheduledMessageListControllerDelegate: DataControllerStateDelegate {
    /// The controller changed the list of observed scheduled messages.
    ///
    /// - Parameters:
    ///   - controller: The controller emitting the change callback.
    ///   - changes: The change to the list of scheduled messages.
    func controller(
        _ controller: ScheduledMessageListController,
        didChangeScheduledMessages changes: [ListChange<ScheduledMessage>]
    )
}

/// A controller which lists the current user's scheduled messages and keeps them up to date.
public class ScheduledMessageListController: DataController, DelegateCallable, DataStoreProvider, @unchecked Sendable {
    /// The query specifying and filtering the list of scheduled messages.
    public let query: ScheduledMessageListQuery

    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The scheduled messages the controller represents.
    ///
    /// To observe changes of the scheduled messages, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    public var scheduledMessages: [ScheduledMessage] {
        startScheduledMessagesObserverIfNeeded()
        return scheduledMessagesObserver.items
    }

    /// A Boolean value that returns whether pagination is finished.
    public private(set) var hasLoadedAllScheduledMessages: Bool = false

    /// Set the delegate of `ScheduledMessageListController` to observe the changes in the system.
    public weak var delegate: ScheduledMessageListControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<ScheduledMessageListControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)

            // After setting delegate local changes will be fetched and observed.
            startScheduledMessagesObserverIfNeeded()
        }
    }

    /// Used for observing the database for changes.
    private(set) lazy var scheduledMessagesObserver: BackgroundListDatabaseObserver<ScheduledMessage, ScheduledMessageDTO> = {
        let request = ScheduledMessageDTO.scheduledMessagesFetchRequest(query: query)

        let observer = self.environment.createScheduledMessageListDatabaseObserver(
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

                $0.controller(self, didChangeScheduledMessages: changes)
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

    private let scheduledMessagesRepository: ScheduledMessagesRepository
    private let environment: Environment
    private var nextCursor: String?

    /// Creates a new `ScheduledMessageListController`.
    ///
    /// - Parameters:
    ///   - query: The query used for filtering the scheduled messages.
    ///   - client: The `Client` instance this controller belongs to.
    init(query: ScheduledMessageListQuery, client: ChatClient, environment: Environment = .init()) {
        self.client = client
        self.query = query
        self.environment = environment
        scheduledMessagesRepository = client.scheduledMessagesRepository
        super.init()
    }

    override public func synchronize(_ completion: (@MainActor (_ error: Error?) -> Void)? = nil) {
        startScheduledMessagesObserverIfNeeded()

        scheduledMessagesRepository.load(query: query) { [weak self] result in
            guard let self else { return }
            if let value = result.value {
                self.nextCursor = value.next
                self.hasLoadedAllScheduledMessages = value.next == nil
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
    /// `scheduledMessagesObserver` to fetch the local data and start observing the changes. It also changes
    /// `state` based on the result.
    private func startScheduledMessagesObserverIfNeeded() {
        guard state == .initialized else { return }
        do {
            try scheduledMessagesObserver.startObserving()
            state = .localDataFetched
        } catch {
            state = .localDataFetchFailed(ClientError(with: error))
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
        }
    }

    // MARK: - Actions

    /// Loads more scheduled messages.
    ///
    /// - Parameters:
    ///   - limit: Limit for the page size.
    ///   - completion: The completion callback.
    public func loadMoreScheduledMessages(
        limit: Int? = nil,
        completion: (@MainActor (Result<[ScheduledMessage], Error>) -> Void)? = nil
    ) {
        let limit = limit ?? query.pagination.pageSize
        var updatedQuery = query
        updatedQuery.pagination = Pagination(pageSize: limit, cursor: nextCursor)
        scheduledMessagesRepository.load(query: updatedQuery) { [weak self] result in
            switch result {
            case let .success(value):
                self?.callback { [weak self] in
                    self?.nextCursor = value.next
                    self?.hasLoadedAllScheduledMessages = value.next == nil
                    completion?(.success(value.messages))
                }
            case let .failure(error):
                self?.callback {
                    completion?(.failure(error))
                }
            }
        }
    }

    /// Changes when a scheduled message is sent. A failed scheduled message can not be changed: delete it and schedule a new one.
    ///
    /// - Parameters:
    ///   - id: The id of the scheduled message.
    ///   - scheduledAt: When to send the message, at most 120 days from now and not in the past. The server rounds it up to the
    ///   next whole minute, at least 1 minute from now.
    ///   - completion: Called when the message is rescheduled locally, with the scheduled message or an error. The new date
    ///   is sent to the server right after, see `ScheduledMessage.syncState`.
    public func rescheduleMessage(
        id: String,
        scheduledAt: Date,
        completion: (@MainActor (Result<ScheduledMessage, Error>) -> Void)? = nil
    ) {
        scheduledMessagesRepository.reschedule(id: id, scheduledAt: scheduledAt) { result in
            self.callback { completion?(result) }
        }
    }

    /// Deletes a scheduled message, so it is never sent.
    ///
    /// - Parameters:
    ///   - id: The id of the scheduled message.
    ///   - completion: Called when the message is deleted, with an error if it failed.
    public func deleteScheduledMessage(id: String, completion: (@MainActor (Error?) -> Void)? = nil) {
        scheduledMessagesRepository.delete(id: id) { error in
            self.callback { completion?(error) }
        }
    }

    /// Sends the changes of a scheduled message that failed to reach the server again.
    ///
    /// A scheduled message is saved locally first and its `syncState` is `.failed` when it could not be scheduled
    /// or updated on the server.
    ///
    /// - Parameters:
    ///   - id: The id of the scheduled message.
    ///   - completion: Called when the message is queued to be sent again, with an error if it failed.
    public func resendScheduledMessage(id: String, completion: (@MainActor (Error?) -> Void)? = nil) {
        scheduledMessagesRepository.resend(id: id) { error in
            self.callback { completion?(error) }
        }
    }

    /// Sends a scheduled message right away.
    ///
    /// - Parameters:
    ///   - id: The id of the scheduled message.
    ///   - completion: Called when sending started, with an error if it failed.
    public func sendScheduledMessageNow(id: String, completion: (@MainActor (Error?) -> Void)? = nil) {
        scheduledMessagesRepository.sendNow(id: id) { error in
            self.callback { completion?(error) }
        }
    }
}

extension ScheduledMessageListController {
    struct Environment {
        var createScheduledMessageListDatabaseObserver: (
            _ database: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<ScheduledMessageDTO>,
            _ itemCreator: @escaping (ScheduledMessageDTO) throws -> ScheduledMessage
        )
            -> BackgroundListDatabaseObserver<ScheduledMessage, ScheduledMessageDTO> = {
                BackgroundListDatabaseObserver(
                    database: $0,
                    fetchRequest: $1,
                    itemCreator: $2,
                    itemReuseKeyPaths: (\ScheduledMessage.id, \ScheduledMessageDTO.id)
                )
            }
    }
}
