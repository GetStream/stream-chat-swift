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

/// Repository for handling the current user's scheduled messages.
final class ScheduledMessagesRepository: @unchecked Sendable {
    typealias Page = (messages: [ScheduledMessage], next: String?)

    private weak var client: ChatClient?
    private let database: DatabaseContainer
    private let apiClient: APIClient

    init(client: ChatClient, database: DatabaseContainer, apiClient: APIClient) {
        self.client = client
        self.database = database
        self.apiClient = apiClient
    }

    // MARK: - Requests

    /// Loads scheduled messages and saves them to the database.
    ///
    /// When the whole list is loaded, the scheduled messages missing from it are removed from the database,
    /// for example the ones that were sent while the app was offline.
    func load(query: ScheduledMessageListQuery, completion: @escaping @Sendable (Result<Page, Error>) -> Void) {
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
                        if isWholeList, let context = session as? NSManagedObjectContext {
                            let ids = Set(response.scheduledMessages.map(\.id))
                            let request = ScheduledMessageDTO.scheduledMessagesFetchRequest(query: .init())
                            ScheduledMessageDTO.load(by: request, context: context)
                                .filter { !ids.contains($0.id) }
                                .forEach { context.delete($0) }
                        }
                        return (messages, next)
                    },
                    completion: completion
                )
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func schedule(
        id: String,
        cid: ChannelId,
        content: ScheduledMessageContent,
        scheduledAt: Date,
        completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void
    ) {
        makeMessageRequest(content, id: id) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(message):
                let endpoint: Endpoint<SendMessageResponsePayload> = .sendMessage(
                    type: cid.type.rawValue,
                    id: cid.id,
                    sendMessageRequest: SendMessageRequest(message: message, scheduledAt: scheduledAt)
                )
                // Not queued offline: the user is told right away that the message could not be scheduled.
                apiClient.unmanagedRequest(endpoint: endpoint) { [weak self] result in
                    self?.save(result.map(\.scheduledMessage), completion: completion)
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    /// Edits a scheduled message.
    ///
    /// Without a `parentId` in `content`, the message keeps the thread it was scheduled in.
    func update(
        id: String,
        content: ScheduledMessageContent,
        scheduledAt: Date?,
        completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void
    ) {
        database.read({ session -> ScheduledMessageContent in
            guard content.parentId == nil, let existing = session.scheduledMessage(id: id) else { return content }
            var content = content
            content.parentId = existing.parentMessageId
            content.showReplyInChannel = existing.showReplyInChannel
            return content
        }, completion: { [weak self] result in
            guard let self else { return }
            makeMessageRequest(result.value ?? content, id: nil) { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(message):
                    let endpoint: Endpoint<UpdateScheduledMessageResponse> = .updateScheduledMessage(
                        id: id,
                        updateScheduledMessageRequest: UpdateScheduledMessageRequest(message: message, scheduledAt: scheduledAt)
                    )
                    apiClient.request(endpoint: endpoint) { [weak self] result in
                        self?.save(result.map(\.scheduledMessage), completion: completion)
                    }
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        })
    }

    func reschedule(
        id: String,
        scheduledAt: Date,
        completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void
    ) {
        let endpoint: Endpoint<UpdateScheduledMessageResponse> = .updateScheduledMessage(
            id: id,
            updateScheduledMessageRequest: UpdateScheduledMessageRequest(scheduledAt: scheduledAt)
        )
        apiClient.request(endpoint: endpoint) { [weak self] result in
            self?.save(result.map(\.scheduledMessage), completion: completion)
        }
    }

    func delete(id: String, completion: @escaping @Sendable (Error?) -> Void) {
        apiClient.request(endpoint: .deleteScheduledMessage(id: id)) { [weak self] result in
            if let error = result.error {
                completion(error)
                return
            }
            self?.database.write({ session in
                session.deleteScheduledMessage(id: id)
            }, completion: completion)
        }
    }

    func sendNow(id: String, completion: @escaping @Sendable (Error?) -> Void) {
        apiClient.request(endpoint: .sendScheduledMessageNow(id: id)) { [weak self] result in
            self?.save(result.map(\.scheduledMessage)) { completion($0.error) }
        }
    }

    // MARK: - Helpers

    private func save(
        _ result: Result<ScheduledMessageResponse?, Error>,
        completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void
    ) {
        switch result {
        case let .success(payload):
            guard let payload else {
                completion(.failure(ClientError.Unexpected("Missing `scheduled_message` in the response.")))
                return
            }
            database.write(converting: { session in
                try session.saveScheduledMessage(payload: payload).asModel()
            }, completion: completion)
        case let .failure(error):
            completion(.failure(error))
        }
    }

    // MARK: - Attachments

    // Attachments are uploaded when the message is scheduled, so it is sent later with remote URLs.
    private func makeMessageRequest(
        _ content: ScheduledMessageContent,
        id: String?,
        completion: @escaping @Sendable (Result<MessageRequest, Error>) -> Void
    ) {
        uploadAttachments(content.attachments[...], uploaded: []) { result in
            completion(result.map { attachments in
                MessageRequest(
                    attachments: attachments,
                    custom: content.extraData,
                    id: id,
                    mentionedUsers: content.mentionedUserIds,
                    parentId: content.parentId,
                    quotedMessageId: content.quotedMessageId,
                    showInChannel: content.showReplyInChannel,
                    text: content.text
                )
            })
        }
    }

    private func uploadAttachments(
        _ remaining: ArraySlice<AnyAttachmentPayload>,
        uploaded: [MessageAttachmentPayload],
        completion: @escaping @Sendable (Result<[MessageAttachmentPayload], Error>) -> Void
    ) {
        guard let attachment = remaining.first else {
            completion(.success(uploaded))
            return
        }

        let next: @Sendable (Data) -> Void = { [weak self] payload in
            do {
                let item = try MessageAttachmentPayload.fromStoredPayload(payload, type: attachment.type)
                self?.uploadAttachments(remaining.dropFirst(), uploaded: uploaded + [item], completion: completion)
            } catch {
                completion(.failure(error))
            }
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
            filter: cid == nil && statuses == nil ? nil : ScheduledMessagesFilter(cid: cid, status: statuses),
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
