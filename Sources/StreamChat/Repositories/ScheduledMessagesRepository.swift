//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

struct ScheduledMessageContent: Sendable {
    var text: String
    var attachments: [AnyAttachmentPayload]
    var mentionedUserIds: [UserId]
    var quotedMessageId: MessageId?
    var parentId: MessageId?
    var showReplyInChannel: Bool
    var extraData: [String: RawJSON]
}

/// A response containing a list of scheduled messages and pagination information.
struct ScheduledMessageListResponse: Sendable {
    var scheduledMessages: [ScheduledMessage]
    var next: String?
}

/// Repository for handling the current user's scheduled messages.
final class ScheduledMessagesRepository: @unchecked Sendable {
    private let database: DatabaseContainer
    private let apiClient: APIClient

    init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
    }

    // MARK: - Requests

    /// Loads scheduled messages and saves them to the database.
    ///
    /// When the whole list is loaded, the scheduled messages missing from it are removed from the database,
    /// for example the ones that were sent while the app was offline.
    func loadScheduledMessages(
        query: ScheduledMessageListQuery,
        completion: @escaping @Sendable (Result<ScheduledMessageListResponse, Error>) -> Void
    ) {
        let endpoint: Endpoint<QueryScheduledMessagesResponse> = .queryScheduledMessages(
            queryScheduledMessagesRequest: query.toRequest()
        )
        apiClient.request(endpoint: endpoint) { [weak self] result in
            switch result {
            case let .success(response):
                let next = response.next.flatMap { $0.isEmpty ? nil : $0 }
                let isWholeList = query.filter == nil && query.pagination.cursor == nil && next == nil
                self?.database.write(
                    converting: { session in
                        let messages = response.scheduledMessages.compactMap { payload in
                            do {
                                return try session.saveScheduledMessage(payload: payload).asModel()
                            } catch {
                                log.error("Failed to save the scheduled message \(payload.id): \(error)")
                                return nil
                            }
                        }
                        if isWholeList {
                            session.deleteScheduledMessages(notIn: Set(response.scheduledMessages.map(\.id)), cid: nil)
                        }
                        return ScheduledMessageListResponse(scheduledMessages: messages, next: next)
                    },
                    completion: completion
                )
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    /// Schedules a message locally.
    ///
    /// The message is in the list right away. The `MessageScheduler` sends it to the server once its attachments are uploaded.
    func schedule(
        id: String,
        cid: ChannelId,
        content: ScheduledMessageContent,
        scheduledAt: Date,
        completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void
    ) {
        database.write(converting: { session in
            try session.createNewScheduledMessage(id: id, cid: cid, content: content, scheduledAt: scheduledAt).asModel()
        }, completion: completion)
    }

    /// Edits a scheduled message locally. The `MessageScheduler` syncs it with the server.
    ///
    /// Without a `parentId` in `content`, the message keeps the thread it was scheduled in.
    func update(
        id: String,
        content: ScheduledMessageContent,
        scheduledAt: Date?,
        completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void
    ) {
        database.write(converting: { session in
            try session.updateScheduledMessage(id: id, content: content, scheduledAt: scheduledAt).asModel()
        }, completion: completion)
    }

    /// Changes when a scheduled message is sent, locally. The `MessageScheduler` syncs it with the server.
    func reschedule(
        id: String,
        scheduledAt: Date,
        completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void
    ) {
        database.write(converting: { session in
            try session.updateScheduledMessage(id: id, content: nil, scheduledAt: scheduledAt).asModel()
        }, completion: completion)
    }

    /// Sends the local changes of a scheduled message that failed to reach the server again.
    func resend(id: String, completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void) {
        database.write(converting: { session in
            guard let dto = session.scheduledMessage(id: id), let message = dto.message else {
                throw ClientError.ScheduledMessageDoesNotExist(id: id)
            }
            switch message.localMessageState {
            case .sendingFailed:
                message.localMessageState = .pendingSend
            case .syncingFailed:
                message.localMessageState = .pendingSync
            default:
                throw ClientError.ScheduledMessageHasNoPendingChanges(id: id)
            }
            dto.syncErrorReason = nil
            dto.syncErrorMessage = nil
            dto.isSyncErrorLocal = false
            return try dto.asModel()
        }, completion: completion)
    }

    /// Deletes a scheduled message. One that is not on the server yet is only deleted locally.
    func delete(id: String, completion: @escaping @Sendable (Error?) -> Void) {
        database.write(converting: { session in
            guard let dto = session.scheduledMessage(id: id) else { return false }
            guard dto.isLocalOnly else { return true }
            session.deleteScheduledMessage(id: id)
            return false
        }, completion: { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(true):
                apiClient.request(endpoint: .deleteScheduledMessage(id: id)) { [weak self] result in
                    if let error = result.error {
                        completion(error)
                        return
                    }
                    self?.database.write({ session in
                        session.deleteScheduledMessage(id: id)
                    }, completion: completion)
                }
            case .success(false):
                completion(nil)
            case let .failure(error):
                completion(error)
            }
        })
    }

    /// Marks a scheduled message to be sent right away. The `MessageScheduler` sends it once its local changes and
    /// attachments are on the server, so it is never sent with older content.
    func sendNow(id: String, completion: @escaping @Sendable (Error?) -> Void) {
        database.write({ session in
            guard let dto = session.scheduledMessage(id: id) else {
                throw ClientError.ScheduledMessageDoesNotExist(id: id)
            }
            try session.validateQuotedMessage(dto.quotedMessageId)
            dto.isPendingSendNow = true
        }, completion: completion)
    }

    // MARK: - Syncing with the server

    /// Sends the local changes of a scheduled message to the server: schedules a new one, updates an existing one, or,
    /// once they are on the server, sends it right away.
    ///
    /// Called by the `MessageScheduler` once the attachments of the message are uploaded. Completes with `nil` when the
    /// message is no longer scheduled: the server sent it right away because its date passed while offline, it was
    /// already sent, or it was deleted on another device.
    func sendPendingChanges(id: String, completion: @escaping @Sendable (Result<ScheduledMessage?, Error>) -> Void) {
        enum Request {
            case schedule(cid: ChannelId, request: SendMessageRequest)
            case update(UpdateScheduledMessageRequest)
            case sendNow
        }

        database.write(converting: { session -> Request in
            guard let dto = session.scheduledMessage(id: id), let message = dto.message else {
                throw ClientError.ScheduledMessageDoesNotExist(id: id)
            }
            let scheduledAt = dto.scheduledAt.bridgeDate
            switch message.localMessageState {
            case .pendingSend:
                message.localMessageState = .sending
                let cid = try ChannelId(cid: dto.cid)
                return .schedule(cid: cid, request: SendMessageRequest(message: message.asMessageRequest(), scheduledAt: scheduledAt))
            case .pendingSync:
                message.localMessageState = .syncing
                // The backend ignores the id of the message.
                return .update(UpdateScheduledMessageRequest(
                    message: message.asMessageRequest(),
                    scheduledAt: dto.hasPendingScheduledAt ? scheduledAt : nil
                ))
            case nil where dto.isPendingSendNow:
                return .sendNow
            default:
                throw ClientError.ScheduledMessageHasNoPendingChanges(id: id)
            }
        }, completion: { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(.schedule(cid, request)):
                let endpoint: Endpoint<SendMessageResponsePayload> = .sendMessage(
                    type: cid.type.rawValue,
                    id: cid.id,
                    sendMessageRequest: request
                )
                // Not queued offline: the `MessageScheduler` waits for the connection and sends it again.
                apiClient.request(endpoint: endpoint) { [weak self] result in
                    if case let .success(response) = result, response.scheduledMessage == nil {
                        // A date in the past is sent right away as a normal message.
                        self?.saveSentMessage(response.message, scheduledMessageId: id, completion: completion)
                        return
                    }
                    self?.complete(
                        id: id,
                        failedState: .sendingFailed,
                        pendingState: .pendingSend,
                        with: result.map(\.scheduledMessage),
                        completion: completion
                    )
                }
            case let .success(.update(request)):
                let endpoint: Endpoint<UpdateScheduledMessageResponse> = .updateScheduledMessage(
                    id: id,
                    updateScheduledMessageRequest: request
                )
                apiClient.request(endpoint: endpoint) { [weak self] result in
                    self?.complete(
                        id: id,
                        failedState: .syncingFailed,
                        pendingState: .pendingSync,
                        with: result.map(\.scheduledMessage),
                        completion: completion
                    )
                }
            case .success(.sendNow):
                apiClient.request(endpoint: .sendScheduledMessageNow(id: id)) { [weak self] result in
                    self?.completeSendNow(id: id, with: result.map(\.scheduledMessage), completion: completion)
                }
            case let .failure(error):
                completion(.failure(error))
            }
        })
    }

    // MARK: - Helpers

    private func completeSendNow(
        id: String,
        with result: Result<ScheduledMessageResponse, Error>,
        completion: @escaping @Sendable (Result<ScheduledMessage?, Error>) -> Void
    ) {
        guard case let .success(payload) = result else {
            // Kept to be sent now, after the changes are sent again when it is retried.
            complete(id: id, failedState: .syncingFailed, pendingState: nil, with: result.map { $0 }, completion: completion)
            return
        }
        database.write(converting: { session -> ScheduledMessage? in
            session.scheduledMessage(id: id)?.isPendingSendNow = false
            return try session.saveScheduledMessage(payload: payload).asModel()
        }, completion: completion)
    }

    private func complete(
        id: String,
        failedState: LocalMessageState,
        // The state to send the changes again once connected, `nil` when only sending now is pending.
        pendingState: LocalMessageState?,
        with result: Result<ScheduledMessageResponse?, Error>,
        completion: @escaping @Sendable (Result<ScheduledMessage?, Error>) -> Void
    ) {
        switch result {
        case let .success(payload):
            guard let payload else {
                completion(.failure(ClientError.Unexpected("Missing `scheduled_message` in the response.")))
                return
            }
            database.write(converting: { session -> ScheduledMessage? in
                // Deleted locally while the request was in flight: saving the response would bring it back.
                guard let dto = session.scheduledMessage(id: id) else { return nil }
                dto.message?.localMessageState = nil
                return try session.saveScheduledMessage(payload: payload).asModel()
            }, completion: { [weak self] result in
                guard case .success(nil) = result, pendingState == .pendingSend, let self else {
                    completion(result)
                    return
                }
                // It was only deleted locally, since it was not on the server yet.
                apiClient.request(endpoint: .deleteScheduledMessage(id: payload.id)) { deleteResult in
                    if let error = deleteResult.error {
                        log.error("Failed to delete the scheduled message \(payload.id) on the server: \(error)")
                    }
                    completion(.success(nil))
                }
            })
        case let .failure(error):
            // Without a connection, the changes are sent again once connected.
            let isEphemeral = ClientError.isEphemeral(error: error)
            let apiError = (error as? ClientError)?.apiError
            let reason = apiError.flatMap(ScheduledMessageFailure.ServerRejection.Reason.init(apiError:))
            if reason == .scheduledMessageAlreadySent || reason == .scheduledMessageCanceled {
                // It went out at its date, or was deleted on another device, while this device was offline.
                database.write({ session in
                    session.deleteScheduledMessage(id: id)
                }, completion: { error in
                    completion(error.map { .failure($0) } ?? .success(nil))
                })
                return
            }
            database.write({ session in
                guard let dto = session.scheduledMessage(id: id) else { return }
                dto.message?.localMessageState = isEphemeral ? pendingState : failedState
                // Kept so the user sees why, for example that the scheduling limit of the channel is reached.
                dto.syncErrorReason = isEphemeral ? nil : reason?.rawValue
                dto.syncErrorMessage = isEphemeral ? nil : apiError?.message ?? error.localizedDescription
                dto.isSyncErrorLocal = !isEphemeral && apiError == nil
            }, completion: { _ in
                completion(.failure(error))
            })
        }
    }

    private func saveSentMessage(
        _ message: MessageResponse,
        scheduledMessageId: String,
        completion: @escaping @Sendable (Result<ScheduledMessage?, Error>) -> Void
    ) {
        database.write({ session in
            // Saved first: when the sent message has the id of the scheduled one, it keeps its content.
            let messageDTO = try session.saveMessage(payload: message, syncOwnReactions: false, skipDraftUpdate: false, cache: nil)
            if messageDTO.localMessageState == .sending || messageDTO.localMessageState == .sendingFailed {
                messageDTO.markMessageAsSent()
            }
            session.deleteScheduledMessage(id: scheduledMessageId)
        }, completion: { error in
            completion(error.map { .failure($0) } ?? .success(nil))
        })
    }
}

extension ClientError {
    final class ScheduledMessageDoesNotExist: ClientError, @unchecked Sendable {
        init(id: String) {
            super.init("There is no scheduled message with id: \(id).")
        }
    }

    final class ScheduledMessageHasACommand: ClientError, @unchecked Sendable {
        init() {
            super.init("Slash commands cannot be scheduled.")
        }
    }

    final class ScheduledMessageQuotesADeletedMessage: ClientError, @unchecked Sendable {
        init() {
            super.init("The quoted message was deleted. Remove the quote and try again.")
        }
    }

    final class ScheduledMessageIsTooFarAhead: ClientError, @unchecked Sendable {
        init(maxLeadTime: TimeInterval) {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.day, .hour, .minute]
            formatter.unitsStyle = .full
            formatter.maximumUnitCount = 1
            let leadTime = formatter.string(from: maxLeadTime) ?? "\(Int(maxLeadTime)) seconds"
            super.init("A message can be scheduled at most \(leadTime) ahead. Pick an earlier time.")
        }
    }

    final class ScheduledMessagesChannelLimitReached: ClientError, @unchecked Sendable {
        init(limit: Int) {
            super.init("You can have at most \(limit) scheduled messages in this channel.")
        }
    }

    final class ScheduledMessagesUserLimitReached: ClientError, @unchecked Sendable {
        init(limit: Int) {
            super.init("You can have at most \(limit) scheduled messages.")
        }
    }

    final class ScheduledMessageHasNoPendingChanges: ClientError, @unchecked Sendable {
        init(id: String) {
            super.init("The scheduled message with id: \(id) has no changes to send to the server.")
        }
    }
}

// MARK: - Request

extension ScheduledMessageListQuery {
    /// The backend filters by channel and status only, with exact values.
    func toRequest() -> QueryScheduledMessagesRequest {
        var cid: String?
        var statuses: [String]?
        if let filter {
            Self.collect(filter, cid: &cid, statuses: &statuses)
        }
        return QueryScheduledMessagesRequest(
            filter: cid == nil && statuses == nil ? nil : ScheduledMessagesFilter(cid: cid, status: statuses?.map(ScheduledMessageQueryStatus.init(rawValue:))),
            limit: min(max(pagination.pageSize, 1), 100),
            next: pagination.cursor
        )
    }

    private static func collect(_ filter: Filter<ScheduledMessageListFilterScope>, cid: inout String?, statuses: inout [String]?) {
        switch filter.operator {
        case FilterOperator.and.rawValue:
            let filters = filter.value as? [Filter<ScheduledMessageListFilterScope>] ?? []
            filters.forEach { collect($0, cid: &cid, statuses: &statuses) }
        case FilterOperator.equal.rawValue, FilterOperator.in.rawValue:
            let values = stringValues(of: filter.value)
            switch filter.key {
            case FilterKey<ScheduledMessageListFilterScope, ChannelId>.cid.rawValue:
                cid = values.first
            case FilterKey<ScheduledMessageListFilterScope, String>.status.rawValue:
                statuses = values
            default:
                log.warning("Scheduled messages can not be filtered by \(filter.key ?? "")")
            }
        default:
            log.warning("Scheduled messages can not be filtered with \(filter.operator)")
        }
    }

    private static func stringValues(of value: FilterValue) -> [String] {
        switch value {
        case let cid as ChannelId:
            return [cid.rawValue]
        case let cids as [ChannelId]:
            return cids.map(\.rawValue)
        case let string as String:
            return [string]
        case let strings as [String]:
            return strings
        default:
            return []
        }
    }
}

// MARK: - Async

extension ScheduledMessagesRepository {
    func load(query: ScheduledMessageListQuery) async throws -> Page {
        try await withCheckedThrowingContinuation { continuation in
            load(query: query) { continuation.resume(with: $0) }
        }
    }

    func schedule(id: String, cid: ChannelId, content: ScheduledMessageContent, scheduledAt: Date) async throws -> ScheduledMessage {
        try await withCheckedThrowingContinuation { continuation in
            schedule(id: id, cid: cid, content: content, scheduledAt: scheduledAt) { continuation.resume(with: $0) }
        }
    }

    func update(id: String, content: ScheduledMessageContent, scheduledAt: Date?) async throws -> ScheduledMessage {
        try await withCheckedThrowingContinuation { continuation in
            update(id: id, content: content, scheduledAt: scheduledAt) { continuation.resume(with: $0) }
        }
    }

    func reschedule(id: String, scheduledAt: Date) async throws -> ScheduledMessage {
        try await withCheckedThrowingContinuation { continuation in
            reschedule(id: id, scheduledAt: scheduledAt) { continuation.resume(with: $0) }
        }
    }

    func resend(id: String) async throws -> ScheduledMessage {
        try await withCheckedThrowingContinuation { continuation in
            resend(id: id) { continuation.resume(with: $0) }
        }
    }

    func delete(id: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            delete(id: id) { continuation.resume(with: $0) }
        }
    }

    func sendNow(id: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            sendNow(id: id) { continuation.resume(with: $0) }
        }
    }
}

private extension ScheduledMessageFailure.ServerRejection.Reason {
    /// The reason of the server, or one derived from the status code when the server gives none.
    init?(apiError: APIError) {
        if let reason = apiError.exceptionFields?["reason"] {
            self.init(rawValue: reason)
        } else if apiError.statusCode == 429 {
            self = .rateLimited
        } else if apiError.statusCode >= 500 {
            self = .serverUnavailable
        } else {
            return nil
        }
    }
}
