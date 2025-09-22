//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class DraftMessagesRepository_Mock: DraftMessagesRepository, @unchecked Sendable {
    // MARK: - Load Drafts

    var loadDrafts_callCount = 0
    var loadDrafts_calledWith: DraftListQuery?
    var loadDrafts_completion: ((Result<DraftListResponse, Error>) -> Void)?

    override func loadDrafts(
        query: DraftListQuery,
        completion: @escaping (Result<DraftListResponse, Error>) -> Void
    ) {
        loadDrafts_callCount += 1
        loadDrafts_calledWith = query
        loadDrafts_completion = completion
    }

    // MARK: - Update Draft

    var updateDraft_callCount = 0
    var updateDraft_calledWith: (
        cid: ChannelId,
        threadId: MessageId?,
        text: String,
        isSilent: Bool,
        showReplyInChannel: Bool,
        command: String?,
        arguments: String?,
        attachments: [AnyAttachmentPayload],
        mentionedUserIds: [UserId],
        quotedMessageId: MessageId?,
        extraData: [String: RawJSON]
    )?
    var updateDraft_completion: ((Result<DraftMessage, Error>) -> Void)?

    override func updateDraft(
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
        completion: ((Result<DraftMessage, Error>) -> Void)?
    ) {
        updateDraft_callCount += 1
        updateDraft_calledWith = (
            cid: cid,
            threadId: threadId,
            text: text,
            isSilent: isSilent,
            showReplyInChannel: showReplyInChannel,
            command: command,
            arguments: arguments,
            attachments: attachments,
            mentionedUserIds: mentionedUserIds,
            quotedMessageId: quotedMessageId,
            extraData: extraData
        )
        updateDraft_completion = completion
    }

    // MARK: - Get Draft

    var getDraft_callCount = 0
    var getDraft_calledWith: (cid: ChannelId, threadId: MessageId?)?
    var getDraft_completion: ((Result<DraftMessage?, Error>) -> Void)?

    override func getDraft(
        for cid: ChannelId,
        threadId: MessageId?,
        completion: ((Result<DraftMessage?, Error>) -> Void)?
    ) {
        getDraft_callCount += 1
        getDraft_calledWith = (cid: cid, threadId: threadId)
        getDraft_completion = completion
    }

    // MARK: - Delete Draft

    var deleteDraft_callCount = 0
    var deleteDraft_calledWith: (cid: ChannelId, threadId: MessageId?)?
    var deleteDraft_completion: ((Error?) -> Void)?

    override func deleteDraft(
        for cid: ChannelId,
        threadId: MessageId?,
        completion: @escaping (Error?) -> Void
    ) {
        deleteDraft_callCount += 1
        deleteDraft_calledWith = (cid: cid, threadId: threadId)
        deleteDraft_completion = completion
    }
}
