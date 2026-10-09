//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamChat

// Stands in for the scheduled messages API until the backend and the SDK support it.
// Due messages are only sent while the app is running.
@MainActor
final class DemoScheduledMessagesService {
    static let shared = DemoScheduledMessagesService()

    nonisolated static let minimumLeadTime: TimeInterval = 60
    nonisolated static let maximumLeadTime: TimeInterval = 120 * 24 * 60 * 60
    nonisolated static let lateDeliveryTolerance: TimeInterval = 60 * 60
    nonisolated static let channelLimit = 10
    nonisolated static let userLimit = 100

    // Pending messages first, then failed ones, each sorted by `scheduledAt`.
    @Published private(set) var scheduledMessages: [DemoScheduledMessage] = []

    private var client: ChatClient?
    private var deliveryTimer: Timer?
    // Keeps the controllers sending due messages alive until their completion is called.
    private var sendingControllers: [String: AnyObject] = [:]
    private let responseDelay: UInt64 = 300_000_000

    private init() {}

    // MARK: - Lifecycle

    func start(client: ChatClient) {
        stop()
        self.client = client
        commit(loadPersistedMessages())
        deliveryTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.deliverDueMessages()
            }
        }
        deliverDueMessages()
    }

    func stop() {
        deliveryTimer?.invalidate()
        deliveryTimer = nil
        sendingControllers.removeAll()
        scheduledMessages = []
        client = nil
    }

    // MARK: - Queries

    func scheduledMessage(id: String) -> DemoScheduledMessage? {
        scheduledMessages.first { $0.id == id }
    }

    // Mirrors the `schedule-message` capability, which channels do not report yet.
    func canScheduleMessages(in channel: ChatChannel?) -> Bool {
        guard AppConfig.shared.demoAppConfig.isScheduledMessagesEnabled, let channel else {
            return false
        }
        return channel.canSendMessage
    }

    // MARK: - Actions

    func schedule(
        cid: ChannelId,
        content: DemoScheduledMessage.Content,
        scheduledAt: Date,
        completion: @escaping (Result<DemoScheduledMessage, Error>) -> Void
    ) {
        respond(completion) { [self] in
            try validate(scheduledAt: scheduledAt)
            let pending = scheduledMessages.filter(\.isPending)
            guard pending.count < Self.userLimit else {
                throw DemoScheduledMessageError.userLimitReached
            }
            guard pending.filter({ $0.cid == cid }).count < Self.channelLimit else {
                throw DemoScheduledMessageError.channelLimitReached
            }
            let now = Date()
            let message = DemoScheduledMessage(
                id: UUID().uuidString.lowercased(),
                cid: cid,
                content: content,
                scheduledAt: scheduledAt,
                status: .scheduled,
                failureReason: nil,
                createdAt: now,
                updatedAt: now
            )
            upsert(message)
            return message
        }
    }

    // Rescheduling a failed message schedules it again.
    func update(
        id: String,
        content: DemoScheduledMessage.Content? = nil,
        scheduledAt: Date? = nil,
        completion: @escaping (Result<DemoScheduledMessage, Error>) -> Void
    ) {
        respond(completion) { [self] in
            guard var message = scheduledMessage(id: id) else {
                throw DemoScheduledMessageError.notFound
            }
            guard message.status != .sending else {
                throw DemoScheduledMessageError.alreadySending
            }
            if let scheduledAt {
                try validate(scheduledAt: scheduledAt)
                message.scheduledAt = scheduledAt
                message.status = .scheduled
                message.failureReason = nil
            }
            if let content {
                message.content = content
            }
            message.updatedAt = Date()
            upsert(message)
            return message
        }
    }

    func delete(id: String, completion: ((Result<DemoScheduledMessage, Error>) -> Void)? = nil) {
        respond(completion ?? { _ in }) { [self] in
            guard let message = scheduledMessage(id: id) else {
                throw DemoScheduledMessageError.notFound
            }
            guard message.status != .sending else {
                throw DemoScheduledMessageError.alreadySending
            }
            remove(id: id)
            return message
        }
    }

    func sendNow(id: String, completion: ((Result<DemoScheduledMessage, Error>) -> Void)? = nil) {
        respond(completion ?? { _ in }) { [self] in
            guard let message = scheduledMessage(id: id) else {
                throw DemoScheduledMessageError.notFound
            }
            guard message.status != .sending else {
                throw DemoScheduledMessageError.alreadySending
            }
            deliver(message)
            return message
        }
    }

    // MARK: - Delivery

    private func deliverDueMessages() {
        let now = Date()
        for message in scheduledMessages where message.status == .scheduled && message.scheduledAt <= now {
            if now.timeIntervalSince(message.scheduledAt) > Self.lateDeliveryTolerance {
                markFailed(id: message.id, reason: .expired)
            } else {
                deliver(message)
            }
        }
    }

    private func deliver(_ message: DemoScheduledMessage) {
        guard let client else { return }

        if let channel = client.channelController(for: message.cid).channel {
            if channel.isFrozen {
                markFailed(id: message.id, reason: .channelFrozen)
                return
            }
            if !channel.canSendMessage {
                markFailed(id: message.id, reason: .noPermission)
                return
            }
        }

        var sending = message
        sending.status = .sending
        upsert(sending)

        let id = message.id
        let content = message.content
        let completion: @MainActor (Result<MessageId, Error>) -> Void = { [weak self] result in
            self?.sendingControllers[id] = nil
            switch result {
            case .success:
                self?.remove(id: id)
            case let .failure(error):
                log.error("Failed to send scheduled message \(id): \(error)")
                self?.markFailed(id: id, reason: .internalError)
            }
        }

        if let parentId = content.parentId {
            let controller = client.messageController(cid: message.cid, messageId: parentId)
            sendingControllers[id] = controller
            controller.createNewReply(
                text: content.text,
                attachments: content.attachments,
                mentionedUserIds: content.mentionedUserIds,
                showReplyInChannel: content.showReplyInChannel,
                quotedMessageId: content.quotedMessageId,
                extraData: content.extraData,
                completion: completion
            )
        } else {
            let controller = client.channelController(for: message.cid)
            sendingControllers[id] = controller
            controller.createNewMessage(
                text: content.text,
                attachments: content.attachments,
                mentionedUserIds: content.mentionedUserIds,
                quotedMessageId: content.quotedMessageId,
                extraData: content.extraData,
                completion: completion
            )
        }
    }

    private func markFailed(id: String, reason: DemoScheduledMessage.FailureReason) {
        guard var message = scheduledMessage(id: id) else { return }
        message.status = .failed
        message.failureReason = reason
        message.updatedAt = Date()
        upsert(message)
    }

    // MARK: - Storage

    private func validate(scheduledAt: Date) throws {
        let leadTime = scheduledAt.timeIntervalSinceNow
        if leadTime < Self.minimumLeadTime {
            throw DemoScheduledMessageError.scheduledAtTooSoon
        }
        if leadTime > Self.maximumLeadTime {
            throw DemoScheduledMessageError.scheduledAtTooFar
        }
    }

    private func respond<Value>(
        _ completion: @escaping (Result<Value, Error>) -> Void,
        _ operation: @escaping () throws -> Value
    ) {
        Task { [responseDelay] in
            try? await Task.sleep(nanoseconds: responseDelay)
            completion(Result(catching: operation))
        }
    }

    private func upsert(_ message: DemoScheduledMessage) {
        var messages = scheduledMessages
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
        } else {
            messages.append(message)
        }
        commit(messages)
    }

    private func remove(id: String) {
        commit(scheduledMessages.filter { $0.id != id })
    }

    private func commit(_ messages: [DemoScheduledMessage]) {
        scheduledMessages = messages.sorted {
            if $0.isPending != $1.isPending {
                return $0.isPending
            }
            return $0.scheduledAt < $1.scheduledAt
        }
        persist()
    }

    private var storageKey: String? {
        client?.currentUserId.map { "demo.scheduledMessages.\($0)" }
    }

    private func persist() {
        guard let storageKey, let data = try? JSONEncoder().encode(scheduledMessages) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func loadPersistedMessages() -> [DemoScheduledMessage] {
        guard
            let storageKey,
            let data = UserDefaults.standard.data(forKey: storageKey),
            let messages = try? JSONDecoder().decode([DemoScheduledMessage].self, from: data)
        else { return [] }

        // A send interrupted by closing the app is retried.
        return messages.map { message in
            var message = message
            if message.status == .sending {
                message.status = .scheduled
            }
            return message
        }
    }
}
