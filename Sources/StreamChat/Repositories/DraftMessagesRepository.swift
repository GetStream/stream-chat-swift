//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData

struct DraftListResponse: Sendable {
    var drafts: [DraftMessage]
    var next: String?
}

class DraftMessagesRepository: @unchecked Sendable {
    private let database: DatabaseContainer
    private let apiClient: APIClient
    
    init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
    }
    
    func loadDrafts(
        query: DraftListQuery,
        completion: @escaping @Sendable(Result<DraftListResponse, Error>) -> Void
    ) {
        apiClient.request(endpoint: .drafts(query: query)) { [weak self] result in
            switch result {
            case .success(let response):
                nonisolated(unsafe) var drafts: [DraftMessage] = []
                self?.database.write({ session in
                    drafts = try response.drafts.compactMap {
                        guard let channelId = $0.channelPayload?.cid else {
                            return nil
                        }
                        return DraftMessage(try session
                            .saveDraftMessage(payload: $0, for: channelId, cache: nil)
                            .asModel())
                    }
                }, completion: { error in
                    if let error {
                        completion(.failure(error))
                        return
                    }
                    completion(.success(DraftListResponse(drafts: drafts, next: response.next)))
                })
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func updateDraft(
        for cid: ChannelId,
        threadId: MessageId?,
        text: String,
        isSilent: Bool,
        showReplyInChannel: Bool,
        command: String?,
        arguments: String?,
        attachments: [AnyAttachmentPayload],
        mentionedUserIds: [UserId],
        quotedMessageId: MessageId?,
        extraData: [String: RawJSON],
        completion: (@Sendable(Result<DraftMessage, Error>) -> Void)?
    ) {
        nonisolated(unsafe) var draftRequestBody: DraftMessageRequestBody?
        database.write({ (session) in
            let newMessageDTO = try session.createNewDraftMessage(
                in: cid,
                text: text,
                command: command,
                arguments: arguments,
                parentMessageId: threadId,
                attachments: attachments,
                mentionedUserIds: mentionedUserIds,
                showReplyInChannel: showReplyInChannel,
                isSilent: isSilent,
                quotedMessageId: quotedMessageId,
                extraData: extraData
            )
            draftRequestBody = newMessageDTO.asDraftRequestBody()
        }) { error in
            guard let requestBody = draftRequestBody, error == nil else {
                completion?(.failure(error ?? ClientError.Unknown()))
                return
            }

            self.apiClient.request(
                endpoint: .updateDraftMessage(channelId: cid, requestBody: requestBody)
            ) { [weak self] result in
                switch result {
                case .success(let response):
                    nonisolated(unsafe) var draft: ChatMessage?
                    self?.database.write({ session in
                        let draftPayload = response.draft
                        let messageDTO = try session.saveDraftMessage(
                            payload: draftPayload,
                            for: cid,
                            cache: nil
                        )
                        draft = try messageDTO.asModel()
                    }, completion: { error in
                        if let draft {
                            completion?(.success(DraftMessage(draft)))
                        } else if let error {
                            completion?(.failure(error))
                        }
                    })
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
        }
    }

    func getDraft(
        for cid: ChannelId,
        threadId: MessageId?,
        completion: (@Sendable(Result<DraftMessage?, Error>) -> Void)?
    ) {
        apiClient.request(
            endpoint: .getDraftMessage(channelId: cid, threadId: threadId)
        ) { [weak self] result in
            switch result {
            case .success(let response):
                nonisolated(unsafe) var draft: ChatMessage?
                self?.database.write({ session in
                    let messageDTO = try session.saveDraftMessage(
                        payload: response.draft,
                        for: cid,
                        cache: nil
                    )
                    draft = try messageDTO.asModel()
                }) { error in
                    if let draft {
                        completion?(.success(DraftMessage(draft)))
                    } else if let error {
                        completion?(.failure(error))
                    }
                }
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    func deleteDraft(
        for cid: ChannelId,
        threadId: MessageId?,
        completion: @escaping @Sendable(Error?) -> Void
    ) {
        database.write { session in
            session.deleteDraftMessage(in: cid, threadId: threadId)
        }
        apiClient.request(
            endpoint: .deleteDraftMessage(channelId: cid, threadId: threadId)
        ) { result in
            completion(result.error)
        }
    }
}
