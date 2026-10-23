//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents the current user's list of `ScheduledMessage` for the specified query.
public final class ScheduledMessageList: Sendable {
    private let query: ScheduledMessageListQuery
    private let scheduledMessagesRepository: ScheduledMessagesRepository
    @MainActor private var stateBuilder: StateBuilder<ScheduledMessageListState>

    init(query: ScheduledMessageListQuery, client: ChatClient, environment: Environment = .init()) {
        self.query = query
        scheduledMessagesRepository = environment.scheduledMessagesRepositoryBuilder(
            client.databaseContainer,
            client.apiClient
        )
        stateBuilder = StateBuilder {
            environment.stateBuilder(
                query,
                client.databaseContainer
            )
        }
    }

    // MARK: - Accessing the State

    /// An observable object representing the current state of the scheduled message list.
    @MainActor public var state: ScheduledMessageListState { stateBuilder.state }

    /// Fetches the most recent state from the server and updates the local store.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func get() async throws {
        try await loadScheduledMessages(cursor: nil, limit: query.pagination.pageSize)
    }

    // MARK: - Scheduled Messages Pagination

    /// Loads more scheduled messages and updates ``ScheduledMessageListState/scheduledMessages``.
    ///
    /// - Parameter limit: The limit for the page size. The default limit is the page size of the query.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of loaded scheduled messages.
    @discardableResult public func loadMoreScheduledMessages(limit: Int? = nil) async throws -> [ScheduledMessage] {
        let cursor = await state.nextCursor
        return try await loadScheduledMessages(cursor: cursor, limit: limit ?? query.pagination.pageSize)
    }

    // MARK: - Managing Scheduled Messages

    /// Changes when a scheduled message is sent. A failed scheduled message can not be changed: delete it and schedule a new one.
    ///
    /// The new date is sent to the server right after it is saved locally, see `ScheduledMessage.status`.
    ///
    /// - Parameters:
    ///   - id: The id of the scheduled message.
    ///   - scheduledAt: When to send the message, at most 120 days from now and not in the past. The server rounds it up to the
    ///   next whole minute, at least 1 minute from now.
    ///
    /// - Throws: An error while rescheduling the message locally.
    /// - Returns: The rescheduled message.
    @discardableResult public func rescheduleMessage(id: String, scheduledAt: Date) async throws -> ScheduledMessage {
        try await scheduledMessagesRepository.reschedule(id: id, scheduledAt: scheduledAt)
    }

    /// Deletes a scheduled message, so it is never sent.
    ///
    /// - Parameter id: The id of the scheduled message.
    ///
    /// - Throws: An error while deleting the scheduled message.
    public func deleteScheduledMessage(id: String) async throws {
        try await scheduledMessagesRepository.delete(id: id)
    }

    /// Sends a scheduled message right away.
    ///
    /// - Parameter id: The id of the scheduled message.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func sendScheduledMessageNow(id: String) async throws {
        try await scheduledMessagesRepository.sendNow(id: id)
    }

    /// Sends the changes of a scheduled message that failed to reach the server again.
    ///
    /// A scheduled message is saved locally first and its `status` is `.failed` when it could not be scheduled
    /// or updated on the server.
    ///
    /// - Parameter id: The id of the scheduled message.
    ///
    /// - Throws: An error when the scheduled message has no failed changes.
    public func resendScheduledMessage(id: String) async throws {
        try await scheduledMessagesRepository.resend(id: id)
    }

    // MARK: - Private

    @discardableResult private func loadScheduledMessages(cursor: String?, limit: Int) async throws -> [ScheduledMessage] {
        var query = query
        query.pagination = Pagination(pageSize: limit, cursor: cursor)
        let page = try await scheduledMessagesRepository.load(query: query)
        await state.setNextCursor(page.next)
        return page.messages
    }
}

extension ScheduledMessageList {
    struct Environment: Sendable {
        var scheduledMessagesRepositoryBuilder: @Sendable (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ScheduledMessagesRepository = { ScheduledMessagesRepository(database: $0, apiClient: $1) }

        var stateBuilder: @Sendable @MainActor (
            _ query: ScheduledMessageListQuery,
            _ database: DatabaseContainer
        ) -> ScheduledMessageListState = { @MainActor in
            ScheduledMessageListState(query: $0, database: $1)
        }
    }
}
