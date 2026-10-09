//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
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
    /// To observe changes of the scheduled messages, set your class as a delegate of this controller.
    public var scheduledMessages: [ScheduledMessage] {
        startObservingIfNeeded()
        return items.value
    }

    /// A Boolean value that returns whether pagination is finished.
    public private(set) var hasLoadedAllScheduledMessages: Bool = false

    /// Set the delegate of `ScheduledMessageListController` to observe the changes in the system.
    public weak var delegate: ScheduledMessageListControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }

    var multicastDelegate: MulticastDelegate<ScheduledMessageListControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)
            startObservingIfNeeded()
        }
    }

    private let repository: ScheduledMessagesRepository
    private let items = AllocatedUnfairLock<[ScheduledMessage]>([])
    private var observation: AnyCancellable?
    private var nextCursor: String?

    init(query: ScheduledMessageListQuery, client: ChatClient) {
        self.query = query
        self.client = client
        repository = client.scheduledMessagesRepository
        super.init()
    }

    override public func synchronize(_ completion: (@MainActor (_ error: Error?) -> Void)? = nil) {
        startObservingIfNeeded()

        repository.load(query: query) { [weak self] result in
            guard let self else { return }
            if let value = result.value {
                nextCursor = value.next
                hasLoadedAllScheduledMessages = value.next == nil
            }
            if let error = result.error {
                state = .remoteDataFetchFailed(ClientError(with: error))
            } else {
                state = .remoteDataFetched
            }
            callback { completion?(result.error) }
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
        var updatedQuery = query
        updatedQuery.pagination = Pagination(pageSize: limit ?? query.pagination.pageSize, cursor: nextCursor)
        repository.load(query: updatedQuery) { [weak self] result in
            self?.callback { [weak self] in
                if let value = result.value {
                    self?.nextCursor = value.next
                    self?.hasLoadedAllScheduledMessages = value.next == nil
                }
                completion?(result.map(\.messages))
            }
        }
    }

    /// Changes when a scheduled message is sent. A failed scheduled message is scheduled again.
    ///
    /// - Parameters:
    ///   - id: The id of the scheduled message.
    ///   - scheduledAt: When to send the message. At least 1 minute and at most 120 days from now.
    ///   - completion: Called when the message is rescheduled, with the scheduled message or an error.
    public func rescheduleMessage(
        id: String,
        scheduledAt: Date,
        completion: (@MainActor (Result<ScheduledMessage, Error>) -> Void)? = nil
    ) {
        repository.reschedule(id: id, scheduledAt: scheduledAt) { result in
            self.callback { completion?(result) }
        }
    }

    /// Deletes a scheduled message, so it is never sent.
    ///
    /// - Parameters:
    ///   - id: The id of the scheduled message.
    ///   - completion: Called when the message is deleted, with an error if it failed.
    public func deleteScheduledMessage(id: String, completion: (@MainActor (Error?) -> Void)? = nil) {
        repository.delete(id: id) { error in
            self.callback { completion?(error) }
        }
    }

    /// Sends a scheduled message right away.
    ///
    /// - Parameters:
    ///   - id: The id of the scheduled message.
    ///   - completion: Called when sending started, with an error if it failed.
    public func sendScheduledMessageNow(id: String, completion: (@MainActor (Error?) -> Void)? = nil) {
        repository.sendNow(id: id) { error in
            self.callback { completion?(error) }
        }
    }

    // MARK: - Observing

    private func startObservingIfNeeded() {
        guard state == .initialized else { return }
        items.value = repository.scheduledMessages(matching: query)
        observation = repository.observe { [weak self] _ in
            self?.updateItems()
        }
        state = .localDataFetched
    }

    private func updateItems() {
        let newItems = repository.scheduledMessages(matching: query)
        let oldItems = items.withLock { items in
            defer { items = newItems }
            return items
        }
        let changes = Self.changes(from: oldItems, to: newItems)
        guard !changes.isEmpty else { return }

        delegateCallback { [weak self] in
            guard let self else { return }
            $0.controller(self, didChangeScheduledMessages: changes)
        }
    }

    private static func changes(from oldItems: [ScheduledMessage], to newItems: [ScheduledMessage]) -> [ListChange<ScheduledMessage>] {
        let oldIndices = Dictionary(uniqueKeysWithValues: oldItems.enumerated().map { ($1.id, $0) })
        let newIds = Set(newItems.map(\.id))

        let removals: [ListChange<ScheduledMessage>] = oldItems.enumerated().compactMap { index, item in
            newIds.contains(item.id) ? nil : .remove(item, index: IndexPath(item: index, section: 0))
        }
        let others: [ListChange<ScheduledMessage>] = newItems.enumerated().compactMap { index, item in
            let indexPath = IndexPath(item: index, section: 0)
            guard let oldIndex = oldIndices[item.id] else {
                return .insert(item, index: indexPath)
            }
            if oldIndex != index {
                return .move(item, fromIndex: IndexPath(item: oldIndex, section: 0), toIndex: indexPath)
            }
            return oldItems[oldIndex] == item ? nil : .update(item, index: indexPath)
        }
        return removals + others
    }
}
