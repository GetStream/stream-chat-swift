//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of MessageUpdater
final class MessageUpdaterMock<ExtraData: ExtraDataTypes>: MessageUpdater<ExtraData> {
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
    @Atomic var createNewReply_showReplyInChannel: Bool?
    @Atomic var createNewReply_extraData: ExtraData.Message?
    @Atomic var createNewReply_completion: ((Result<MessageId, Error>) -> Void)?
    
    @Atomic var loadReplies_cid: ChannelId?
    @Atomic var loadReplies_messageId: MessageId?
    @Atomic var loadReplies_pagination: MessagesPagination?
    @Atomic var loadReplies_completion: ((Error?) -> Void)?
    
    @Atomic var flagMessage_flag: Bool?
    @Atomic var flagMessage_messageId: MessageId?
    @Atomic var flagMessage_cid: ChannelId?
    @Atomic var flagMessage_completion: ((Error?) -> Void)?
    
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
        createNewReply_showReplyInChannel = nil
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
    
    override func createNewReply(
        in cid: ChannelId,
        text: String,
        command: String?,
        arguments: String?,
        parentMessageId: MessageId?,
        showReplyInChannel: Bool,
        extraData: ExtraData.Message,
        completion: ((Result<MessageId, Error>) -> Void)? = nil
    ) {
        createNewReply_cid = cid
        createNewReply_text = text
        createNewReply_command = command
        createNewReply_arguments = arguments
        createNewReply_parentMessageId = parentMessageId
        createNewReply_showReplyInChannel = showReplyInChannel
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
}
