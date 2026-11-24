//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

struct ScheduledMessageContent: Sendable {
    var text: String
    var attachments: [AnyAttachmentPayload]
    var mentionedUserIds: [UserId]
    var mentionedHere = false
    var mentionedChannel = false
    var mentionedGroupIds: [String] = []
    var mentionedRoles: [String] = []
    var quotedMessageId: MessageId?
    var parentId: MessageId?
    var showReplyInChannel: Bool
    var isSilent = false
    var skipPush = false
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

    func usage(cid: ChannelId, completion: @escaping @Sendable (Result<ScheduledMessagesUsage, Error>) -> Void) {
        database.read({ try $0.scheduledMessagesUsage(cid: cid) }, completion: completion)
    }

    func validate(
        cid: ChannelId?,
        text: String?,
        quotedMessageId: MessageId?,
        scheduledAt: Date?,
        editing id: String?,
        completion: @escaping @Sendable (Error?) -> Void
    ) {
        database.read({
            try $0.validateScheduledMessage(
                cid: cid,
                text: text,
                quotedMessageId: quotedMessageId,
                scheduledAt: scheduledAt,
                editing: id
            )
        }, completion: { completion($0.error) })
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
    /// Without a `parentId` in `content`, the message keeps the thread it was scheduled in. Without `content`, only the
    /// date changes.
    func update(
        id: String,
        content: ScheduledMessageContent?,
        scheduledAt: Date?,
        completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void
    ) {
        database.write(converting: { session -> (ScheduledMessage, scheduledAgain: Bool) in
            guard let dto = session.scheduledMessage(id: id) else {
                throw ClientError.ScheduledMessageDoesNotExist(id: id)
            }
            guard dto.isServerFailed, let scheduledAt else {
                return (try session.updateScheduledMessage(id: id, content: content, scheduledAt: scheduledAt).asModel(), false)
            }
            let new = try session.scheduleFailedMessageAgain(id: id, newId: .newUniqueId, content: content, scheduledAt: scheduledAt)
            return (try new.asModel(), true)
        }, completion: { [weak self] result in
            if case .success((_, scheduledAgain: true)) = result {
                self?.apiClient.request(endpoint: .deleteScheduledMessage(id: id)) { result in
                    if let error = result.error, !error.isBackendNotFound404StatusCode {
                        log.warning("Failed to delete the failed scheduled message \(id) that was scheduled again: \(error)")
                    }
                }
            }
            completion(result.map(\.0))
        })
    }

    /// Changes when a scheduled message is sent, locally. The `MessageScheduler` syncs it with the server.
    func reschedule(
        id: String,
        scheduledAt: Date,
        completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void
    ) {
        update(id: id, content: nil, scheduledAt: scheduledAt, completion: completion)
    }

    /// Sends the local changes of a scheduled message that failed to reach the server again.
    func resend(id: String, completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void) {
        database.write(converting: { session in
            guard let dto = session.scheduledMessage(id: id) else {
                throw ClientError.ScheduledMessageDoesNotExist(id: id)
            }
            guard dto.restartFailedChanges() else {
                throw ClientError.ScheduledMessageHasNoPendingChanges(id: id)
            }
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
                    let apiError = (result.error as? ClientError)?.apiError
                    let reason = apiError.flatMap(ScheduledMessageFailure.ServerRejection.Reason.init(apiError:))
                    let isGoneFromServer = result.error?.isBackendNotFound404StatusCode == true
                        || reason == .scheduledMessageAlreadySent || reason == .scheduledMessageCanceled
                    if let error = result.error, !isGoneFromServer {
                        completion(reason == .scheduledMessageSending ? ClientError.ScheduledMessageIsBeingSent(id: id) : error)
                        return
                    }
                    self?.database.write({ session in
                        session.deleteScheduledMessage(id: id)
                    }, completion: { error in
                        guard error == nil, isGoneFromServer else { return completion(error) }
                        completion(
                            reason == .scheduledMessageAlreadySent
                                ? ClientError.ScheduledMessageAlreadySent(id: id)
                                : ClientError.ScheduledMessageDoesNotExist(id: id)
                        )
                    })
                }
            case .success(false):
                completion(nil)
            case let .failure(error):
                completion(error)
            }
        })
    }

    /// Marks a scheduled message to be sent right away. The `MessageScheduler` sends it once its local changes and
    /// attachments are on the server, so it is never sent with older content. Failed local changes are sent again first.
    func sendNow(id: String, completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void) {
        database.write(converting: { session in
            guard let dto = session.scheduledMessage(id: id) else {
                throw ClientError.ScheduledMessageDoesNotExist(id: id)
            }
            try session.validateQuotedMessage(dto.quotedMessageId)
            dto.isPendingSendNow = true
            dto.restartFailedChanges()
            return try dto.asModel()
        }, completion: completion)
    }

    // MARK: - Syncing with the server

    /// Sends the local changes of a scheduled message to the server: schedules a new one, updates an existing one, or,
    /// once they are on the server, sends it right away.
    ///
    /// Called by the `MessageScheduler` once the attachments of the message are uploaded. Completes with `nil` when the
    /// server sent it right away because its date passed while offline. Completes with
    /// `ClientError.ScheduledMessageAlreadySent` or `ClientError.ScheduledMessageDoesNotExist` when it was already sent,
    /// or deleted on this or another device, and removes it locally.
    func sendPendingChanges(
        id: String,
        didSendNow: (@Sendable (ScheduledMessageSentEvent) -> Void)? = nil,
        completion: @escaping @Sendable (Result<ScheduledMessage?, Error>) -> Void
    ) {
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
                return .schedule(cid: cid, request: SendMessageRequest(
                    message: message.asMessageRequest(),
                    scheduledAt: scheduledAt,
                    skipPush: message.skipPush
                ))
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
                        self?.saveSentMessage(response.message, scheduledMessageId: id, didSendNow: didSendNow, completion: completion)
                        return
                    }
                    // There is no error code for a message whose id is taken.
                    if let apiError = (result.error as? ClientError)?.apiError, apiError.code == 4,
                       apiError.message.contains("already exists") {
                        // The response of an earlier attempt, which sent the message right away, was lost.
                        self?.saveSentMessage(nil, scheduledMessageId: id, didSendNow: didSendNow, completion: completion)
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
                guard case .success(nil) = result else {
                    completion(result)
                    return
                }
                let deleted = ClientError.ScheduledMessageDoesNotExist(id: id)
                guard pendingState == .pendingSend, let self else {
                    completion(.failure(deleted))
                    return
                }
                // It was only deleted locally, since it was not on the server yet.
                apiClient.request(endpoint: .deleteScheduledMessage(id: payload.id)) { deleteResult in
                    if let error = deleteResult.error {
                        log.error("Failed to delete the scheduled message \(payload.id) on the server: \(error)")
                    }
                    completion(.failure(deleted))
                }
            })
        case let .failure(error):
            // Without a connection, the changes are sent again once connected.
            let isEphemeral = ClientError.isEphemeral(error: error)
            let apiError = (error as? ClientError)?.apiError
            let reason = apiError.flatMap(ScheduledMessageFailure.ServerRejection.Reason.init(apiError:))
            // A 404 means the message is gone only when sending now. Scheduling and updating also fail with it for a
            // deleted quoted message, or a missing parent message or channel.
            let isGoneFromServer = pendingState == nil && error.isBackendNotFound404StatusCode
            if reason == .scheduledMessageAlreadySent || reason == .scheduledMessageCanceled || isGoneFromServer {
                // It went out at its date, or was deleted on another device, while this device was offline.
                database.write({ session in
                    session.deleteScheduledMessage(id: id)
                }, completion: { error in
                    completion(.failure(error ?? (
                        reason == .scheduledMessageAlreadySent
                            ? ClientError.ScheduledMessageAlreadySent(id: id)
                            : ClientError.ScheduledMessageDoesNotExist(id: id)
                    )))
                })
                return
            }
            database.write({ session in
                guard let dto = session.scheduledMessage(id: id) else { return }
                if reason == .scheduledMessageNotEditable {
                    // The server failed to send it meanwhile. Rescheduling it schedules a copy with the local changes.
                    dto.status = ScheduledMessageServerStatus.failed.rawValue
                    dto.isPendingSendNow = false
                    dto.message?.localMessageState = nil
                    return
                }
                dto.message?.localMessageState = isEphemeral ? pendingState : failedState
                // Kept so the user sees why, for example that the scheduling limit of the channel is reached.
                dto.syncErrorReason = isEphemeral ? nil : reason?.rawValue
                dto.syncErrorMessage = isEphemeral ? nil : apiError?.message ?? error.localizedDescription
                dto.isSyncErrorLocal = !isEphemeral && apiError == nil
            }, completion: { _ in
                // The limits are optional in the config, so the server can be the first to tell.
                switch reason {
                case .scheduledLimitChannel:
                    completion(.failure(ClientError.ScheduledMessagesChannelLimitReached(limit: nil)))
                case .scheduledLimitUser:
                    completion(.failure(ClientError.ScheduledMessagesUserLimitReached(limit: nil)))
                default:
                    completion(.failure(error))
                }
            })
        }
    }

    private func saveSentMessage(
        // `nil` when the server only told that the message already exists.
        _ message: MessageResponse?,
        scheduledMessageId: String,
        didSendNow: (@Sendable (ScheduledMessageSentEvent) -> Void)?,
        completion: @escaping @Sendable (Result<ScheduledMessage?, Error>) -> Void
    ) {
        database.write(converting: { session -> ScheduledMessageSentEvent? in
            let scheduledMessage = try? session.scheduledMessage(id: scheduledMessageId)?.asModel()
            // Saved first: when the sent message has the id of the scheduled one, it keeps its content.
            let messageDTO = try message.map {
                try session.saveMessage(payload: $0, syncOwnReactions: false, skipDraftUpdate: false, cache: nil)
            } ?? session.message(id: scheduledMessageId)
            if messageDTO?.localMessageState == .sending || messageDTO?.localMessageState == .sendingFailed {
                messageDTO?.markMessageAsSent()
            }
            session.deleteScheduledMessage(id: scheduledMessageId)
            return scheduledMessage.map {
                ScheduledMessageSentEvent(
                    scheduledMessage: $0,
                    messageId: message?.id ?? scheduledMessageId,
                    sentNow: true,
                    createdAt: Date()
                )
            }
        }, completion: { result in
            if case let .success(event?) = result {
                didSendNow?(event)
            }
            completion(result.map { _ in nil })
        })
    }
}

extension ClientError {
    /// There is no scheduled message with the given id: it is not in the local database, or the server no longer
    /// has it, for example because it was deleted on another device.
    public final class ScheduledMessageDoesNotExist: ClientError, @unchecked Sendable {
        init(id: String) {
            super.init("There is no scheduled message with id: \(id).")
        }
    }

    /// The scheduled message was already sent, so the server no longer has it.
    public final class ScheduledMessageAlreadySent: ClientError, @unchecked Sendable {
        init(id: String) {
            super.init("The scheduled message with id: \(id) was already sent.")
        }
    }

    /// The server is sending the scheduled message right now, so it can't be changed or deleted.
    public final class ScheduledMessageIsBeingSent: ClientError, @unchecked Sendable {
        init(id: String) {
            super.init("The scheduled message with id: \(id) is being sent.")
        }
    }

    /// The message starts with a slash command, which cannot be scheduled.
    public final class ScheduledMessageHasACommand: ClientError, @unchecked Sendable {
        init() {
            super.init("Slash commands cannot be scheduled.")
        }
    }

    /// The scheduled message quotes a message that was deleted.
    public final class ScheduledMessageQuotesADeletedMessage: ClientError, @unchecked Sendable {
        init() {
            super.init("The quoted message was deleted. Remove the quote and try again.")
        }
    }

    /// The date is further ahead than the app allows.
    public final class ScheduledMessageIsTooFarAhead: ClientError, @unchecked Sendable {
        init(maxLeadTime: TimeInterval) {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.day, .hour, .minute]
            formatter.unitsStyle = .full
            formatter.maximumUnitCount = 1
            let leadTime = formatter.string(from: maxLeadTime) ?? "\(Int(maxLeadTime)) seconds"
            super.init("A message can be scheduled at most \(leadTime) ahead. Pick an earlier time.")
        }
    }

    /// The current user has as many pending scheduled messages in the channel as the app allows.
    public final class ScheduledMessagesChannelLimitReached: ClientError, @unchecked Sendable {
        init(limit: Int?) {
            super.init(limit.map { "You can have at most \($0) scheduled messages in this channel." }
                ?? "You have as many scheduled messages in this channel as the app allows.")
        }
    }

    /// The current user has as many pending scheduled messages as the app allows.
    public final class ScheduledMessagesUserLimitReached: ClientError, @unchecked Sendable {
        init(limit: Int?) {
            super.init(limit.map { "You can have at most \($0) scheduled messages." }
                ?? "You have as many scheduled messages as the app allows.")
        }
    }

    final class ScheduledMessageNotEditable: ClientError, @unchecked Sendable {
        init(id: String) {
            super.init("The scheduled message with id: \(id) failed to send and can't be changed.")
        }
    }

    /// The channel of the scheduled message was deleted, so it can't be scheduled again.
    public final class ScheduledMessageChannelDeleted: ClientError, @unchecked Sendable {
        init(id: String) {
            super.init("The channel of the scheduled message with id: \(id) was deleted.")
        }
    }

    final class ScheduledMessageHasNoPendingChanges: ClientError, @unchecked Sendable {
        init(id: String) {
            super.init("The scheduled message with id: \(id) has no changes to send to the server.")
        }
    }
}

private extension ScheduledMessageDTO {
    // Makes failed local changes pending again, so the `MessageScheduler` sends them. Returns `false` without failed changes.
    @discardableResult func restartFailedChanges() -> Bool {
        guard let message else { return false }
        switch message.localMessageState {
        case .sendingFailed:
            message.localMessageState = .pendingSend
        case .syncingFailed:
            message.localMessageState = .pendingSync
        default:
            return false
        }
        syncErrorReason = nil
        syncErrorMessage = nil
        isSyncErrorLocal = false
        message.restartFailedUploads()
        return true
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
    func loadScheduledMessages(query: ScheduledMessageListQuery) async throws -> ScheduledMessageListResponse {
        try await withCheckedThrowingContinuation { continuation in
            loadScheduledMessages(query: query) { continuation.resume(with: $0) }
        }
    }

    func usage(cid: ChannelId) async throws -> ScheduledMessagesUsage {
        try await database.read { try $0.scheduledMessagesUsage(cid: cid) }
    }

    func validate(
        cid: ChannelId?,
        text: String?,
        quotedMessageId: MessageId?,
        scheduledAt: Date?,
        editing id: String?
    ) async throws {
        try await database.read {
            try $0.validateScheduledMessage(
                cid: cid,
                text: text,
                quotedMessageId: quotedMessageId,
                scheduledAt: scheduledAt,
                editing: id
            )
        }
    }

    func delete(id: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            delete(id: id) { continuation.resume(with: $0) }
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
