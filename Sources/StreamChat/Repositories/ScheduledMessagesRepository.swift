//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
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

// Keeps the current user's scheduled messages: loaded once, then kept up to date from responses and events.
// Scheduled messages are not part of channel state, so they are kept in memory instead of the database.
final class ScheduledMessagesRepository: @unchecked Sendable {
    typealias Page = (messages: [ScheduledMessage], next: String?)

    private struct State {
        var userId: UserId?
        var messages: [ScheduledMessage] = []
        var observers: [UUID: @Sendable ([ScheduledMessage]) -> Void] = [:]
    }

    private weak var client: ChatClient?
    private let simulator: ScheduledMessagesSimulator
    private let state = AllocatedUnfairLock(State())
    private var eventsSubscription: AnyCancellable?

    init(client: ChatClient, simulator: ScheduledMessagesSimulator? = nil) {
        self.client = client
        self.simulator = simulator ?? ScheduledMessagesSimulator(client: client)
        eventsSubscription = client.eventNotificationCenter.subscribe(
            filter: { Self.isScheduledMessageEvent($0) },
            handler: { [weak self] event in
                self?.handle(event)
            }
        )
    }

    // MARK: - Local list

    var scheduledMessages: [ScheduledMessage] {
        currentState().messages
    }

    func scheduledMessage(id: String) -> ScheduledMessage? {
        scheduledMessages.first { $0.id == id }
    }

    func scheduledMessages(matching query: ScheduledMessageListQuery) -> [ScheduledMessage] {
        query.sorted(scheduledMessages.filter(query.matches))
    }

    // Calls `handler` on the main queue whenever the local list changes.
    func observe(_ handler: @escaping @Sendable ([ScheduledMessage]) -> Void) -> AnyCancellable {
        let id = UUID()
        state.withLock { $0.observers[id] = handler }
        return AnyCancellable { [weak self] in
            self?.state.withLock { _ = $0.observers.removeValue(forKey: id) }
        }
    }

    func reset() {
        update { $0 = [] }
    }

    // MARK: - Requests

    func load(query: ScheduledMessageListQuery, completion: @escaping @Sendable (Result<Page, Error>) -> Void) {
        simulator.query(query) { [weak self] result in
            guard let self else { return }
            completion(result.map { page in
                let messages = page.messages.map(self.model(from:))
                let isWholeList = query.filter == nil && query.pagination.cursor == nil && page.next == nil
                self.update { current in
                    if isWholeList {
                        current = messages
                    } else {
                        messages.forEach { Self.upsert($0, in: &current) }
                    }
                }
                return (messages, page.next)
            })
        }
    }

    func schedule(
        id: String,
        cid: ChannelId,
        content: ScheduledMessageContent,
        scheduledAt: Date,
        completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void
    ) {
        makeMessagePayload(content) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(message):
                simulator.create(id: id, cid: cid, message: message, scheduledAt: scheduledAt) { [weak self] result in
                    self?.complete(completion, with: result)
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func update(
        id: String,
        content: ScheduledMessageContent,
        scheduledAt: Date?,
        completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void
    ) {
        makeMessagePayload(content) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(message):
                simulator.update(id: id, message: message, scheduledAt: scheduledAt) { [weak self] result in
                    self?.complete(completion, with: result)
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func reschedule(
        id: String,
        scheduledAt: Date,
        completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void
    ) {
        simulator.update(id: id, message: nil, scheduledAt: scheduledAt) { [weak self] result in
            self?.complete(completion, with: result)
        }
    }

    func delete(id: String, completion: @escaping @Sendable (Error?) -> Void) {
        simulator.delete(id: id) { [weak self] result in
            if result.error == nil {
                self?.update { $0.removeAll { $0.id == id } }
            }
            completion(result.error)
        }
    }

    func sendNow(id: String, completion: @escaping @Sendable (Error?) -> Void) {
        simulator.sendNow(id: id) { [weak self] result in
            self?.complete({ completion($0.error) }, with: result)
        }
    }

    // MARK: - Events

    private static func isScheduledMessageEvent(_ event: Event) -> Bool {
        event is ScheduledMessageCreatedEvent
            || event is ScheduledMessageUpdatedEvent
            || event is ScheduledMessageDeletedEvent
            || event is ScheduledMessageSentEvent
            || event is ScheduledMessageFailedEvent
    }

    private func handle(_ event: Event) {
        switch event {
        case let event as ScheduledMessageCreatedEvent:
            update { Self.upsert(event.scheduledMessage, in: &$0) }
        case let event as ScheduledMessageUpdatedEvent:
            update { Self.upsert(event.scheduledMessage, in: &$0) }
        case let event as ScheduledMessageFailedEvent:
            update { Self.upsert(event.scheduledMessage, in: &$0) }
        case let event as ScheduledMessageDeletedEvent:
            update { $0.removeAll { $0.id == event.scheduledMessage.id } }
        case let event as ScheduledMessageSentEvent:
            update { $0.removeAll { $0.id == event.scheduledMessage.id } }
        default:
            break
        }
    }

    // MARK: - Helpers

    private func complete(
        _ completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void,
        with result: Result<SimulatedScheduledMessagePayload, Error>
    ) {
        let result = result.map(model(from:))
        if let message = result.value {
            update { Self.upsert(message, in: &$0) }
        }
        completion(result)
    }

    private func model(from payload: SimulatedScheduledMessagePayload) -> ScheduledMessage {
        let channel = client.flatMap { DataStore(client: $0).channel(cid: payload.cid) }
        return payload.asModel(channel: channel, client: client)
    }

    private func currentState() -> State {
        let userId = client?.currentUserId
        return state.withLock { state in
            if state.userId != userId {
                state.userId = userId
                state.messages = []
            }
            return state
        }
    }

    private func update(_ change: (inout [ScheduledMessage]) -> Void) {
        let userId = client?.currentUserId
        let (messages, observers) = state.withLock { state in
            if state.userId != userId {
                state.userId = userId
                state.messages = []
            }
            change(&state.messages)
            state.messages = ScheduledMessageListQuery().sorted(state.messages)
            return (state.messages, Array(state.observers.values))
        }
        DispatchQueue.main.async {
            observers.forEach { $0(messages) }
        }
    }

    private static func upsert(_ message: ScheduledMessage, in messages: inout [ScheduledMessage]) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
        } else {
            messages.append(message)
        }
    }

    // MARK: - Attachments

    // Attachments are uploaded when the message is scheduled, so it is sent later with remote URLs.
    private func makeMessagePayload(
        _ content: ScheduledMessageContent,
        completion: @escaping @Sendable (Result<SimulatedScheduledMessagePayload.Message, Error>) -> Void
    ) {
        uploadAttachments(content.attachments[...], uploaded: []) { result in
            completion(result.map { attachments in
                SimulatedScheduledMessagePayload.Message(
                    text: content.text,
                    attachments: attachments,
                    mentionedUserIds: content.mentionedUserIds,
                    quotedMessageId: content.quotedMessageId,
                    parentId: content.parentId,
                    showReplyInChannel: content.showReplyInChannel,
                    extraData: content.extraData
                )
            })
        }
    }

    private func uploadAttachments(
        _ remaining: ArraySlice<AnyAttachmentPayload>,
        uploaded: [SimulatedScheduledMessagePayload.Attachment],
        completion: @escaping @Sendable (Result<[SimulatedScheduledMessagePayload.Attachment], Error>) -> Void
    ) {
        guard let attachment = remaining.first else {
            completion(.success(uploaded))
            return
        }

        let next: @Sendable (Data) -> Void = { [weak self] payload in
            let item = SimulatedScheduledMessagePayload.Attachment(type: attachment.type.rawValue, payload: payload)
            self?.uploadAttachments(remaining.dropFirst(), uploaded: uploaded + [item], completion: completion)
        }

        do {
            let payload = try JSONEncoder.stream.encode(attachment.payload.asAnyEncodable)
            guard let localFileURL = attachment.localFileURL else {
                next(payload)
                return
            }
            guard let client else {
                completion(.failure(ClientError.ClientHasBeenDeallocated()))
                return
            }
            client.uploadAttachment(localUrl: localFileURL, progress: nil) { result in
                do {
                    let file = try result.get()
                    next(try Self.payload(payload, replacing: localFileURL, with: file))
                } catch {
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    private static func payload(_ payload: Data, replacing localFileURL: URL, with file: UploadedFile) throws -> Data {
        func replacingLocalURL(in json: RawJSON) -> RawJSON {
            switch json {
            case let .string(value) where value == localFileURL.absoluteString:
                return .string(file.fileURL.absoluteString)
            case let .dictionary(dictionary):
                return .dictionary(dictionary.mapValues(replacingLocalURL))
            case let .array(array):
                return .array(array.map(replacingLocalURL))
            default:
                return json
            }
        }

        var json = replacingLocalURL(in: try JSONDecoder.stream.decode(RawJSON.self, from: payload))
        if case var .dictionary(dictionary) = json, let thumbnailURL = file.thumbnailURL {
            dictionary["thumb_url"] = .string(thumbnailURL.absoluteString)
            json = .dictionary(dictionary)
        }
        return try JSONEncoder.stream.encode(json)
    }
}

// MARK: - Local queries

extension ScheduledMessageListQuery {
    func matches(_ message: ScheduledMessage) -> Bool {
        filter.map { Self.matches($0, message) } ?? true
    }

    func sorted(_ messages: [ScheduledMessage]) -> [ScheduledMessage] {
        guard !sort.isEmpty else {
            return messages.sorted {
                if $0.isPending != $1.isPending {
                    return $0.isPending
                }
                return $0.scheduledAt < $1.scheduledAt
            }
        }

        return messages.sorted { lhs, rhs in
            for sorting in sort {
                let isByCreation = sorting.key == .createdAt
                let left = isByCreation ? lhs.createdAt : lhs.scheduledAt
                let right = isByCreation ? rhs.createdAt : rhs.scheduledAt
                if left != right {
                    return sorting.isAscending ? left < right : left > right
                }
            }
            return false
        }
    }

    private static func matches(_ filter: Filter<ScheduledMessageListFilterScope>, _ message: ScheduledMessage) -> Bool {
        switch filter.operator {
        case FilterOperator.and.rawValue:
            let filters = filter.value as? [Filter<ScheduledMessageListFilterScope>] ?? []
            return filters.allSatisfy { matches($0, message) }
        case FilterOperator.or.rawValue:
            let filters = filter.value as? [Filter<ScheduledMessageListFilterScope>] ?? []
            return filters.contains { matches($0, message) }
        case FilterOperator.equal.rawValue, FilterOperator.in.rawValue:
            let values = stringValues(of: filter.value)
            switch filter.key {
            case FilterKey<ScheduledMessageListFilterScope, ChannelId>.cid.rawValue:
                return values.contains(message.cid.rawValue)
            case FilterKey<ScheduledMessageListFilterScope, String>.status.rawValue:
                return values.contains(message.status.rawValue)
            default:
                log.warning("Scheduled messages can not be filtered by \(filter.key ?? "")")
                return true
            }
        default:
            log.warning("Scheduled messages can not be filtered with \(filter.operator)")
            return true
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
