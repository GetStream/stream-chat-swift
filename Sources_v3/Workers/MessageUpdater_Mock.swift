//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
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
}
