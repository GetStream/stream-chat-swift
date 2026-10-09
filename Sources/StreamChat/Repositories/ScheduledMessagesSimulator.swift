//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Stands in for the scheduled messages endpoints and events until the backend ships them (CHA-5635).
// It follows the backend spec: the same limits, errors and statuses, and the same events, sent to the current user only.
// Messages are stored on the device and sent as regular messages, only while the app is running.
// Replace it with `APIClient` requests and generated OpenAPI models once the endpoints exist.
final class ScheduledMessagesSimulator: @unchecked Sendable {
    static let minimumLeadTime: TimeInterval = 60
    static let maximumLeadTime: TimeInterval = 120 * 24 * 60 * 60
    static let lateDeliveryTolerance: TimeInterval = 60 * 60
    static let channelLimit = 10
    static let userLimit = 100

    private struct State {
        var userId: UserId?
        var messages: [SimulatedScheduledMessagePayload] = []
        var sendingControllers: [String: AnyObject] = [:]
    }

    private weak var client: ChatClient?
    private let state = AllocatedUnfairLock(State())
    private let queue = DispatchQueue(label: "io.getstream.scheduled-messages-simulator")
    private let responseDelay: TimeInterval
    private let deliveryTimer: DispatchSourceTimer

    init(client: ChatClient, responseDelay: TimeInterval = 0.3, deliveryInterval: TimeInterval = 5) {
        self.client = client
        self.responseDelay = responseDelay
        deliveryTimer = DispatchSource.makeTimerSource(queue: queue)
        deliveryTimer.schedule(deadline: .now() + deliveryInterval, repeating: deliveryInterval)
        deliveryTimer.setEventHandler { [weak self] in
            self?.deliverDueMessages()
        }
        deliveryTimer.resume()
    }

    deinit {
        deliveryTimer.cancel()
    }

    // MARK: - Endpoints

    // `POST /channels/{type}/{id}/message` with `scheduled_at`.
    func create(
        id: String,
        cid: ChannelId,
        message: SimulatedScheduledMessagePayload.Message,
        scheduledAt: Date,
        completion: @escaping @Sendable (Result<SimulatedScheduledMessagePayload, Error>) -> Void
    ) {
        respond(completion) { [self] in
            try validate(scheduledAt: scheduledAt)
            if let existing = messages.first(where: { $0.id == id }) {
                return existing
            }
            let pending = messages.filter(\.isPending)
            guard pending.count < Self.userLimit else {
                throw Self.error(400, "You can schedule up to \(Self.userLimit) messages")
            }
            guard pending.filter({ $0.cid == cid }).count < Self.channelLimit else {
                throw Self.error(400, "You can schedule up to \(Self.channelLimit) messages in this channel")
            }
            let now = Date()
            let payload = SimulatedScheduledMessagePayload(
                id: id,
                cid: cid,
                channel: client.flatMap { DataStore(client: $0).channel(cid: cid) }
                    .map { .init(name: $0.name, imageURL: $0.imageURL) },
                message: message,
                scheduledAt: scheduledAt,
                status: ScheduledMessageStatus.scheduled.rawValue,
                failureReason: nil,
                createdAt: now,
                updatedAt: now
            )
            upsert(payload)
            emit(payload) { ScheduledMessageCreatedEvent(scheduledMessage: $0, createdAt: now) }
            return payload
        }
    }

    // `POST /scheduled_messages/query`.
    func query(
        _ query: ScheduledMessageListQuery,
        completion: @escaping @Sendable (Result<(messages: [SimulatedScheduledMessagePayload], next: String?), Error>) -> Void
    ) {
        respond(completion) { [self] in
            let messages = messages
            let payloads = Dictionary(uniqueKeysWithValues: messages.map { ($0.id, $0) })
            let models = messages.map { $0.asModel() }.filter(query.matches)
            let matching = query.sorted(models).compactMap { payloads[$0.id] }
            let offset = query.pagination.cursor.flatMap(Int.init) ?? 0
            let end = min(offset + query.pagination.pageSize, matching.count)
            let page = offset < end ? Array(matching[offset..<end]) : []
            return (page, end < matching.count ? String(end) : nil)
        }
    }

    // `PATCH /scheduled_messages/{id}`.
    func update(
        id: String,
        message: SimulatedScheduledMessagePayload.Message?,
        scheduledAt: Date?,
        completion: @escaping @Sendable (Result<SimulatedScheduledMessagePayload, Error>) -> Void
    ) {
        respond(completion) { [self] in
            var payload = try pendingMessage(id: id)
            if let scheduledAt {
                try validate(scheduledAt: scheduledAt)
                payload.scheduledAt = scheduledAt
                payload.status = ScheduledMessageStatus.scheduled.rawValue
                payload.failureReason = nil
            }
            if let message {
                payload.message = message
            }
            payload.updatedAt = Date()
            upsert(payload)
            emit(payload) { ScheduledMessageUpdatedEvent(scheduledMessage: $0, createdAt: payload.updatedAt) }
            return payload
        }
    }

    // `DELETE /scheduled_messages/{id}`.
    func delete(
        id: String,
        completion: @escaping @Sendable (Result<SimulatedScheduledMessagePayload, Error>) -> Void
    ) {
        respond(completion) { [self] in
            let payload = try pendingMessage(id: id)
            remove(id: id)
            emit(payload) { ScheduledMessageDeletedEvent(scheduledMessage: $0, createdAt: Date()) }
            return payload
        }
    }

    // `POST /scheduled_messages/{id}/send_now`.
    func sendNow(
        id: String,
        completion: @escaping @Sendable (Result<SimulatedScheduledMessagePayload, Error>) -> Void
    ) {
        respond(completion) { [self] in
            let payload = try pendingMessage(id: id)
            return deliver(payload) ?? payload
        }
    }

    // MARK: - Delivery

    private func deliverDueMessages() {
        let now = Date()
        for payload in messages where payload.status == ScheduledMessageStatus.scheduled.rawValue && payload.scheduledAt <= now {
            if now.timeIntervalSince(payload.scheduledAt) > Self.lateDeliveryTolerance {
                fail(payload, reason: .expired)
            } else {
                deliver(payload)
            }
        }
    }

    // Starts sending the message, and returns it with the `sending` status.
    @discardableResult
    private func deliver(_ payload: SimulatedScheduledMessagePayload) -> SimulatedScheduledMessagePayload? {
        guard let client else { return nil }

        if let channel = DataStore(client: client).channel(cid: payload.cid) {
            if channel.isFrozen {
                fail(payload, reason: .channelFrozen)
                return nil
            }
            if !channel.canSendMessage {
                fail(payload, reason: .noPermission)
                return nil
            }
        }

        var sending = payload
        sending.status = ScheduledMessageStatus.sending.rawValue
        sending.updatedAt = Date()
        upsert(sending)
        emit(sending) { ScheduledMessageUpdatedEvent(scheduledMessage: $0, createdAt: sending.updatedAt) }

        let id = payload.id
        let message = payload.message
        let messageId = MessageId.newUniqueId
        let completion: @MainActor (Result<MessageId, Error>) -> Void = { [weak self] result in
            guard let self else { return }
            queue.async {
                self.didDeliver(id: id, result: result)
            }
        }
        let attachments = payload.attachmentModels.toAnyAttachmentPayload()

        if let parentId = message.parentId {
            let controller = client.messageController(cid: payload.cid, messageId: parentId)
            state.withLock { $0.sendingControllers[id] = controller }
            controller.createNewReply(
                messageId: messageId,
                text: message.text,
                attachments: attachments,
                mentionedUserIds: message.mentionedUserIds,
                showReplyInChannel: message.showReplyInChannel,
                quotedMessageId: message.quotedMessageId,
                extraData: message.extraData,
                completion: completion
            )
        } else {
            let controller = client.channelController(for: payload.cid)
            state.withLock { $0.sendingControllers[id] = controller }
            controller.createNewMessage(
                messageId: messageId,
                text: message.text,
                attachments: attachments,
                mentionedUserIds: message.mentionedUserIds,
                quotedMessageId: message.quotedMessageId,
                extraData: message.extraData,
                completion: completion
            )
        }
        return sending
    }

    private func didDeliver(id: String, result: Result<MessageId, Error>) {
        state.withLock { $0.sendingControllers[id] = nil }
        guard let payload = messages.first(where: { $0.id == id }) else { return }

        switch result {
        case let .success(messageId):
            remove(id: id)
            emit(payload) { ScheduledMessageSentEvent(scheduledMessage: $0, messageId: messageId, createdAt: Date()) }
        case let .failure(error):
            log.error("Failed to send the scheduled message \(id): \(error)")
            fail(payload, reason: .internalError)
        }
    }

    private func fail(_ payload: SimulatedScheduledMessagePayload, reason: ScheduledMessageFailureReason) {
        var failed = payload
        failed.status = ScheduledMessageStatus.failed.rawValue
        failed.failureReason = reason.rawValue
        failed.updatedAt = Date()
        upsert(failed)
        emit(failed) { ScheduledMessageFailedEvent(scheduledMessage: $0, createdAt: failed.updatedAt) }
    }

    // MARK: - Storage

    // The current user's messages. Switching users loads the other user's messages.
    private var messages: [SimulatedScheduledMessagePayload] {
        let userId = client?.currentUserId
        return state.withLock { state in
            if state.userId != userId {
                state.userId = userId
                state.messages = userId.map(Self.loadMessages(userId:)) ?? []
                state.sendingControllers = [:]
            }
            return state.messages
        }
    }

    private func pendingMessage(id: String) throws -> SimulatedScheduledMessagePayload {
        guard let payload = messages.first(where: { $0.id == id }) else {
            throw Self.error(404, "This scheduled message no longer exists")
        }
        guard payload.status != ScheduledMessageStatus.sending.rawValue else {
            throw Self.error(409, "Already sent")
        }
        return payload
    }

    private func upsert(_ payload: SimulatedScheduledMessagePayload) {
        var updated = messages
        if let index = updated.firstIndex(where: { $0.id == payload.id }) {
            updated[index] = payload
        } else {
            updated.append(payload)
        }
        save(updated)
    }

    private func remove(id: String) {
        save(messages.filter { $0.id != id })
    }

    private func save(_ messages: [SimulatedScheduledMessagePayload]) {
        let userId = state.withLock { state in
            state.messages = messages
            return state.userId
        }
        guard let userId, let data = try? JSONEncoder().encode(messages) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey(userId: userId))
    }

    private static func loadMessages(userId: UserId) -> [SimulatedScheduledMessagePayload] {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey(userId: userId)),
            let messages = try? JSONDecoder().decode([SimulatedScheduledMessagePayload].self, from: data)
        else { return [] }

        // A send interrupted by closing the app is retried.
        return messages.map { payload in
            var payload = payload
            if payload.status == ScheduledMessageStatus.sending.rawValue {
                payload.status = ScheduledMessageStatus.scheduled.rawValue
            }
            return payload
        }
    }

    private static func storageKey(userId: UserId) -> String {
        "io.getstream.chat.simulated-scheduled-messages.\(userId)"
    }

    // MARK: - Helpers

    private func validate(scheduledAt: Date) throws {
        let leadTime = scheduledAt.timeIntervalSinceNow
        if leadTime < Self.minimumLeadTime {
            throw Self.error(400, "Pick a time at least 1 minute from now")
        }
        if leadTime > Self.maximumLeadTime {
            throw Self.error(400, "Pick a time within 120 days")
        }
    }

    private func respond<Value>(
        _ completion: @escaping @Sendable (Result<Value, Error>) -> Void,
        _ operation: @escaping @Sendable () throws -> Value
    ) {
        queue.asyncAfter(deadline: .now() + responseDelay) {
            completion(Result(catching: operation))
        }
    }

    private func emit(
        _ payload: SimulatedScheduledMessagePayload,
        _ makeEvent: (ScheduledMessage) -> Event
    ) {
        guard let client else { return }
        client.eventNotificationCenter.process(makeEvent(payload.asModel(client: client)))
    }

    private static func error(_ statusCode: Int, _ message: String) -> ClientError {
        ClientError(with: APIError(code: 4, message: message, statusCode: statusCode))
    }
}

// The scheduled message object of the backend spec, as the simulator stores it.
struct SimulatedScheduledMessagePayload: Codable, Sendable {
    struct Message: Codable, Sendable {
        var text: String
        var attachments: [Attachment]
        var mentionedUserIds: [UserId]
        var quotedMessageId: MessageId?
        var parentId: MessageId?
        var showReplyInChannel: Bool
        var extraData: [String: RawJSON]
    }

    struct Attachment: Codable, Sendable {
        var type: String
        var payload: Data
    }

    struct Channel: Codable, Sendable {
        var name: String?
        var imageURL: URL?
    }

    let id: String
    let cid: ChannelId
    var channel: Channel?
    var message: Message
    var scheduledAt: Date
    var status: String
    var failureReason: String?
    let createdAt: Date
    var updatedAt: Date

    var isPending: Bool {
        status != ScheduledMessageStatus.failed.rawValue
    }

    var attachmentModels: [AnyChatMessageAttachment] {
        message.attachments.enumerated().map { index, attachment in
            attachment.asModel(cid: cid, scheduledMessageId: id, index: index)
        }
    }

    // The backend returns the channel it has. The simulator refreshes what it stored with the local channel, when there is one.
    private func channelSummary(in dataStore: DataStore?) -> ScheduledMessageChannel {
        if let localChannel = dataStore?.channel(cid: cid) {
            return ScheduledMessageChannel(cid: cid, name: localChannel.name, imageURL: localChannel.imageURL)
        }
        return ScheduledMessageChannel(cid: cid, name: channel?.name, imageURL: channel?.imageURL)
    }

    // The message is built from what is available locally: the client resolves the author, the mentioned users and the quoted message.
    func asModel(client: ChatClient? = nil) -> ScheduledMessage {
        let dataStore = client.map { DataStore(client: $0) }
        let authorId = client?.currentUserId ?? ""
        let author: ChatUser = dataStore?.currentUser() ?? .placeholder(id: authorId)
        let mentionedUsers = Set(message.mentionedUserIds.map { dataStore?.user(id: $0) ?? .placeholder(id: $0) })
        let quotedMessage = message.quotedMessageId.flatMap { dataStore?.message(id: $0) }

        let chatMessage = ChatMessage(
            id: id,
            cid: cid,
            text: message.text,
            type: message.parentId == nil ? .regular : .reply,
            command: nil,
            createdAt: scheduledAt,
            locallyCreatedAt: nil,
            updatedAt: updatedAt,
            deletedAt: nil,
            arguments: nil,
            parentMessageId: message.parentId,
            showReplyInChannel: message.showReplyInChannel,
            replyCount: 0,
            extraData: message.extraData,
            quotedMessage: quotedMessage,
            isBounced: false,
            isSilent: false,
            isShadowed: false,
            deletedForMe: false,
            reactionScores: [:],
            reactionCounts: [:],
            reactionGroups: [:],
            author: author,
            mentionedUsers: mentionedUsers,
            threadParticipants: [],
            attachments: attachmentModels,
            latestReplies: [],
            localState: nil,
            isFlaggedByCurrentUser: false,
            latestReactions: [],
            currentUserReactions: [],
            isSentByCurrentUser: true,
            pinDetails: nil,
            translations: nil,
            originalLanguage: nil,
            moderationDetails: nil,
            readBy: [],
            poll: nil,
            textUpdatedAt: nil,
            draftReply: nil,
            reminder: nil,
            sharedLocation: nil
        )

        return ScheduledMessage(
            id: id,
            cid: cid,
            channel: channelSummary(in: dataStore),
            message: chatMessage,
            quotedMessageId: message.quotedMessageId,
            scheduledAt: scheduledAt,
            status: ScheduledMessageStatus(rawValue: status),
            failureReason: failureReason.map(ScheduledMessageFailureReason.init(rawValue:)),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private extension ChatUser {
    static func placeholder(id: UserId) -> ChatUser {
        ChatUser(
            id: id,
            name: nil,
            imageURL: nil,
            isOnline: false,
            isBanned: false,
            isFlaggedByCurrentUser: false,
            userRole: .user,
            teamsRole: nil,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            deactivatedAt: nil,
            lastActiveAt: nil,
            teams: [],
            language: nil,
            avgResponseTime: nil,
            extraData: [:]
        )
    }
}

extension SimulatedScheduledMessagePayload.Attachment {
    func asModel(cid: ChannelId, scheduledMessageId: String, index: Int) -> AnyChatMessageAttachment {
        AnyChatMessageAttachment(
            id: AttachmentId(cid: cid, messageId: scheduledMessageId, index: index),
            type: AttachmentType(rawValue: type),
            payload: payload,
            downloadingState: nil,
            uploadingState: nil
        )
    }
}
