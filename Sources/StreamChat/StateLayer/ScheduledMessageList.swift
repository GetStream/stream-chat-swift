//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents the current user's list of `ScheduledMessage` for the specified query.
public final class ScheduledMessageList: Sendable {
    private let client: ChatClient
    private let query: ScheduledMessageListQuery
    private let scheduledMessagesRepository: ScheduledMessagesRepository
    @MainActor private var stateBuilder: StateBuilder<ScheduledMessageListState>

    init(query: ScheduledMessageListQuery, client: ChatClient, environment: Environment = .init()) {
        self.client = client
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
    /// - Returns: An array of loaded scheduled messages, empty when all of them are already loaded.
    @discardableResult public func loadMoreScheduledMessages(limit: Int? = nil) async throws -> [ScheduledMessage] {
        guard await !state.hasLoadedAllScheduledMessages else { return [] }
        let cursor = await state.nextCursor
        return try await loadScheduledMessages(cursor: cursor, limit: limit ?? query.pagination.pageSize)
    }

    // MARK: - Managing Scheduled Messages

    /// Changes when a scheduled message is sent.
    ///
    /// - Important: A message the server failed to send can't be changed, so it is scheduled again as a new message
    /// with a new id, which is returned. The failed one is deleted. A message whose channel was deleted can't be
    /// rescheduled.
    ///
    /// The new date is sent to the server right after it is saved locally, see `ScheduledMessage.status`.
    ///
    /// - Parameters:
    ///   - id: The id of the scheduled message.
    ///   - scheduledAt: When to send the message, at most 120 days from now and not in the past. The server rounds it up to the
    ///   next whole minute, at least 1 minute from now.
    ///
    /// - Throws: An error while rescheduling the message locally, or the error of the request. The new date stays saved
    /// when the request fails, see `ScheduledMessage.status`.
    /// It is `ClientError.ScheduledMessageAlreadySent` or `ClientError.ScheduledMessageDoesNotExist` when the server
    /// already sent the message or no longer has it, which also removes it locally.
    /// - Returns: The rescheduled message.
    @discardableResult public func rescheduleMessage(id: String, scheduledAt: Date) async throws -> ScheduledMessage {
        let messageScheduler = try client.backgroundWorker(of: MessageScheduler.self)
        return try await messageScheduler.waitForAPIRequest {
            scheduledMessagesRepository.reschedule(id: id, scheduledAt: scheduledAt, completion: $0)
        }
    }

    /// Deletes a scheduled message, so it is never sent.
    ///
    /// - Parameter id: The id of the scheduled message.
    ///
    /// - Throws: An error while deleting the scheduled message. It is `ClientError.ScheduledMessageAlreadySent` when
    /// the server already sent the message, and `ClientError.ScheduledMessageDoesNotExist` when the server no longer has it,
    /// for example because it was deleted on another device. In both cases the message is removed locally.
    /// It is `ClientError.ScheduledMessageIsBeingSent` when the server is sending the message right now.
    public func deleteScheduledMessage(id: String) async throws {
        try await scheduledMessagesRepository.delete(id: id)
    }

    /// Sends a scheduled message right away.
    ///
    /// It is marked locally and sent once its local changes and attachments are on the server, so it is never sent
    /// with older content. Failed local changes are sent again first. The message is added to the channel when it is
    /// sent, which is reported by the `ScheduledMessageSentEvent`.
    ///
    /// - Parameter id: The id of the scheduled message.
    ///
    /// - Throws: An error when the message can't be sent, for example when its quoted message was deleted, or the error of
    /// the request, see `ScheduledMessage.status`.
    /// It is `ClientError.ScheduledMessageAlreadySent` or `ClientError.ScheduledMessageDoesNotExist` when the server
    /// already sent the message or no longer has it, which also removes it locally.
    public func sendScheduledMessageNow(id: String) async throws {
        let messageScheduler = try client.backgroundWorker(of: MessageScheduler.self)
        _ = try await messageScheduler.waitForAPIRequest {
            scheduledMessagesRepository.sendNow(id: id, completion: $0)
        }
    }

    /// Sends the changes of a scheduled message that failed to reach the server again.
    ///
    /// A scheduled message is saved locally first and its `status` is `.failed` when it could not be scheduled
    /// or updated on the server.
    ///
    /// - Parameter id: The id of the scheduled message.
    ///
    /// - Throws: An error when the scheduled message has no failed changes, or the error of the request, see
    /// `ScheduledMessage.status`.
    public func resendScheduledMessage(id: String) async throws {
        let messageScheduler = try client.backgroundWorker(of: MessageScheduler.self)
        _ = try await messageScheduler.waitForAPIRequest {
            scheduledMessagesRepository.resend(id: id, completion: $0)
        }
    }

    // MARK: - Private

    @discardableResult private func loadScheduledMessages(cursor: String?, limit: Int) async throws -> [ScheduledMessage] {
        var query = query
        query.pagination = Pagination(pageSize: limit, cursor: cursor)
        let response = try await scheduledMessagesRepository.loadScheduledMessages(query: query)
        await state.setNextCursor(response.next)
        return response.scheduledMessages
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
