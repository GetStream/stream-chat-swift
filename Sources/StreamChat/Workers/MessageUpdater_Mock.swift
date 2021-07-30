//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of MessageUpdater
final class MessageUpdaterMock: MessageUpdater {
    @Atomic var getMessage_cid: ChannelId?
    @Atomic var getMessage_messageId: MessageId?
    @Atomic var getMessage_completion: ((Error?) -> Void)?

    @Atomic var deleteMessage_messageId: MessageId?
    @Atomic var deleteMessage_completion: ((Error?) -> Void)?

    @Atomic var editMessage_messageId: MessageId?
    @Atomic var editMessage_text: String?
    @Atomic var editMessage_completion: ((Error?) -> Void)?
    
    @Atomic var createNewReply_cid: ChannelId?
    @Atomic var createNewReply_text: String?
    @Atomic var createNewReply_command: String?
    @Atomic var createNewReply_arguments: String?
    @Atomic var createNewReply_parentMessageId: MessageId?
    @Atomic var createNewReply_attachments: [AnyAttachmentPayload]?
    @Atomic var createNewReply_mentionedUserIds: [UserId]?
    @Atomic var createNewReply_showReplyInChannel: Bool?
    @Atomic var createNewReply_isSilent: Bool?
    @Atomic var createNewReply_quotedMessageId: MessageId?
    @Atomic var createNewReply_pinning: MessagePinning?
    @Atomic var createNewReply_extraData: [String: RawJSON]?
    @Atomic var createNewReply_completion: ((Result<MessageId, Error>) -> Void)?
    
    @Atomic var loadReplies_cid: ChannelId?
    @Atomic var loadReplies_messageId: MessageId?
    @Atomic var loadReplies_pagination: MessagesPagination?
    @Atomic var loadReplies_completion: ((Error?) -> Void)?
    
    @Atomic var flagMessage_flag: Bool?
    @Atomic var flagMessage_messageId: MessageId?
    @Atomic var flagMessage_cid: ChannelId?
    @Atomic var flagMessage_completion: ((Error?) -> Void)?
    
    @Atomic var addReaction_type: MessageReactionType?
    @Atomic var addReaction_score: Int?
    @Atomic var addReaction_enforceUnique: Bool?
    @Atomic var addReaction_extraData: CustomData?
    @Atomic var addReaction_messageId: MessageId?
    @Atomic var addReaction_completion: ((Error?) -> Void)?
    
    @Atomic var deleteReaction_type: MessageReactionType?
    @Atomic var deleteReaction_messageId: MessageId?
    @Atomic var deleteReaction_completion: ((Error?) -> Void)?

    @Atomic var pinMessage_messageId: MessageId?
    @Atomic var pinMessage_pinning: MessagePinning?
    @Atomic var pinMessage_completion: ((Error?) -> Void)?

    @Atomic var unpinMessage_messageId: MessageId?
    @Atomic var unpinMessage_completion: ((Error?) -> Void)?

    @Atomic var restartFailedAttachmentUploading_id: AttachmentId?
    @Atomic var restartFailedAttachmentUploading_completion: ((Error?) -> Void)?

    @Atomic var resendMessage_messageId: MessageId?
    @Atomic var resendMessage_completion: ((Error?) -> Void)?

    @Atomic var dispatchEphemeralMessageAction_cid: ChannelId?
    @Atomic var dispatchEphemeralMessageAction_messageId: MessageId?
    @Atomic var dispatchEphemeralMessageAction_action: AttachmentAction?
    @Atomic var dispatchEphemeralMessageAction_completion: ((Error?) -> Void)?
    
    // Cleans up all recorded values
    func cleanUp() {
        getMessage_cid = nil
        getMessage_messageId = nil
        getMessage_completion = nil

        deleteMessage_messageId = nil
        deleteMessage_completion = nil

        editMessage_messageId = nil
        editMessage_text = nil
        editMessage_completion = nil
        
        createNewReply_cid = nil
        createNewReply_text = nil
        createNewReply_command = nil
        createNewReply_arguments = nil
        createNewReply_parentMessageId = nil
        createNewReply_attachments = nil
        createNewReply_mentionedUserIds = nil
        createNewReply_showReplyInChannel = nil
        createNewReply_isSilent = nil
        createNewReply_extraData = nil
        createNewReply_completion = nil
        
        loadReplies_cid = nil
        loadReplies_messageId = nil
        loadReplies_pagination = nil
        loadReplies_completion = nil
        
        flagMessage_flag = nil
        flagMessage_messageId = nil
        flagMessage_cid = nil
        flagMessage_completion = nil
        
        addReaction_type = nil
        addReaction_score = nil
        addReaction_extraData = nil
        addReaction_messageId = nil
        addReaction_completion = nil
        
        deleteReaction_type = nil
        deleteReaction_messageId = nil
        deleteReaction_completion = nil

        pinMessage_pinning = nil
        pinMessage_completion = nil
        pinMessage_messageId = nil

        unpinMessage_messageId = nil
        unpinMessage_completion = nil

        restartFailedAttachmentUploading_id = nil
        restartFailedAttachmentUploading_completion = nil

        resendMessage_messageId = nil
        resendMessage_completion = nil

        dispatchEphemeralMessageAction_cid = nil
        dispatchEphemeralMessageAction_messageId = nil
        dispatchEphemeralMessageAction_action = nil
        dispatchEphemeralMessageAction_completion = nil
    }
    
    override func getMessage(cid: ChannelId, messageId: MessageId, completion: ((Error?) -> Void)? = nil) {
        getMessage_cid = cid
        getMessage_messageId = messageId
        getMessage_completion = completion
    }
    
    override func deleteMessage(messageId: MessageId, completion: ((Error?) -> Void)? = nil) {
        deleteMessage_messageId = messageId
        deleteMessage_completion = completion
    }
    
    override func editMessage(messageId: MessageId, text: String, completion: ((Error?) -> Void)? = nil) {
        editMessage_messageId = messageId
        editMessage_text = text
        editMessage_completion = completion
    }

    override func resendMessage(with messageId: MessageId, completion: @escaping (Error?) -> Void) {
        resendMessage_messageId = messageId
        resendMessage_completion = completion
    }
    
    override func createNewReply(
        in cid: ChannelId,
        text: String,
        pinning: MessagePinning?,
        command: String?,
        arguments: String?,
        parentMessageId: MessageId?,
        attachments: [AnyAttachmentPayload],
        mentionedUserIds: [UserId],
        showReplyInChannel: Bool,
        isSilent: Bool,
        quotedMessageId: MessageId?,
        extraData: [String: RawJSON],
        completion: ((Result<MessageId, Error>) -> Void)? = nil
    ) {
        createNewReply_cid = cid
        createNewReply_text = text
        createNewReply_command = command
        createNewReply_arguments = arguments
        createNewReply_parentMessageId = parentMessageId
        createNewReply_attachments = attachments
        createNewReply_mentionedUserIds = mentionedUserIds
        createNewReply_showReplyInChannel = showReplyInChannel
        createNewReply_isSilent = isSilent
        createNewReply_quotedMessageId = quotedMessageId
        createNewReply_pinning = pinning
        createNewReply_extraData = extraData
        createNewReply_completion = completion
    }
    
    override func loadReplies(
        cid: ChannelId,
        messageId: MessageId,
        pagination: MessagesPagination,
        completion: ((Error?) -> Void)? = nil
    ) {
        loadReplies_cid = cid
        loadReplies_messageId = messageId
        loadReplies_pagination = pagination
        loadReplies_completion = completion
    }
    
    override func flagMessage(_ flag: Bool, with messageId: MessageId, in cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        flagMessage_flag = flag
        flagMessage_messageId = messageId
        flagMessage_cid = cid
        flagMessage_completion = completion
    }
    
    override func addReaction(
        _ type: MessageReactionType,
        score: Int,
        enforceUnique: Bool = false,
        extraData: CustomData,
        messageId: MessageId,
        completion: ((Error?) -> Void)? = nil
    ) {
        addReaction_type = type
        addReaction_score = score
        addReaction_extraData = extraData
        addReaction_messageId = messageId
        addReaction_enforceUnique = enforceUnique
        addReaction_completion = completion
    }
    
    override func deleteReaction(
        _ type: MessageReactionType,
        messageId: MessageId,
        completion: ((Error?) -> Void)? = nil
    ) {
        deleteReaction_type = type
        deleteReaction_messageId = messageId
        deleteReaction_completion = completion
    }

    override func pinMessage(messageId: MessageId, pinning: MessagePinning, completion: ((Error?) -> Void)? = nil) {
        pinMessage_messageId = messageId
        pinMessage_pinning = pinning
        pinMessage_completion = completion
    }

    override func unpinMessage(messageId: MessageId, completion: ((Error?) -> Void)? = nil) {
        unpinMessage_messageId = messageId
        unpinMessage_completion = completion
    }

    override func restartFailedAttachmentUploading(
        with id: AttachmentId,
        completion: @escaping (Error?) -> Void
    ) {
        restartFailedAttachmentUploading_id = id
        restartFailedAttachmentUploading_completion = completion
    }
    
    override func dispatchEphemeralMessageAction(
        cid: ChannelId,
        messageId: MessageId,
        action: AttachmentAction,
        completion: ((Error?) -> Void)? = nil
    ) {
        dispatchEphemeralMessageAction_cid = cid
        dispatchEphemeralMessageAction_messageId = messageId
        dispatchEphemeralMessageAction_action = action
        dispatchEphemeralMessageAction_completion = completion
    }
}
