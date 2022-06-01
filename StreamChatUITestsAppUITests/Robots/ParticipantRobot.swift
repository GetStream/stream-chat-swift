//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

/// Simulates participant behavior
final class ParticipantRobot: Robot {

    private var server: StreamMockServer
    private var threadParentId: String?
    private var user: [String: String] = UserDetails.hanSolo
    
    init(_ server: StreamMockServer) {
        self.server = server
    }

    var currentUserId: String {
        UserDetails.userId(for: user)
    }
    
    @discardableResult
    func startTyping() -> Self {
        server.websocketEvent(
            .userStartTyping,
            user: participant(),
            channelId: server.currentChannelId
        )
        return self
    }
    
    @discardableResult
    func stopTyping() -> Self {
        server.websocketEvent(
            .userStopTyping,
            user: participant(),
            channelId: server.currentChannelId
        )
        return self
    }
    
    // Sleep in seconds
    @discardableResult
    func wait(_ duration: TimeInterval) -> Self {
        let sleepTime = UInt32(duration * 1000)
        usleep(sleepTime)
        return self
    }
    
    @discardableResult
    func readMessage() -> Self {
        server.websocketEvent(
            .messageRead,
            user: participant(),
            channelId: server.currentChannelId
        )
        return self
    }
    
    @discardableResult
    func sendMessage(_ text: String,
                     at messageCellIndex: Int? = nil,
                     waitForAppearance: Bool = true,
                     file: StaticString = #filePath,
                     line: UInt = #line) -> Self {
        waitForChannelQueryUpdate()
        
        server.websocketMessage(
            text,
            channelId: server.currentChannelId,
            messageId: TestData.uniqueId,
            eventType: .messageNew,
            user: participant()
        )
        
        if waitForAppearance {
            server.waitForWebsocketMessage(withText: text)
            
            let cell = messageCell(withIndex: messageCellIndex, file: file, line: line).wait()
            let textView = attributes.text(in: cell)
            _ = textView.waitForText(text)
        }
        
        return self
    }

    /// The given text will be decorated with the index, eg "message-10"
    @discardableResult
    func sendMultipleMessages(repeatingText text: String, count: Int) -> Self {
        var texts = [String]()
        for index in 1...count {
            texts.append("\(text)-\(index)")
        }

        texts.forEach {
            sendMessage($0, waitForAppearance: false)
            wait(0.5)
        }
        return self
    }
    
    @discardableResult
    func editMessage(_ text: String) -> Self {
        let messageId = server.lastMessage?[MessagePayloadsCodingKeys.id.rawValue] as? String
        server.websocketMessage(
            text,
            channelId: server.currentChannelId,
            messageId: messageId,
            eventType: .messageUpdated,
            user: participant()
        )
        return self
    }
    
    @discardableResult
    func deleteMessage() -> Self {
        let user = participant()
        guard let userId = user?[UserPayloadsCodingKeys.id.rawValue] as? String else {
            return self
        }
        let message = server.findMessageByUserId(userId)
        let messageId = message?[MessagePayloadsCodingKeys.id.rawValue] as? String
        server.websocketMessage(
            channelId: server.currentChannelId,
            messageId: messageId,
            eventType: .messageDeleted,
            user: user
        )
        return self
    }
    
    @discardableResult
    func addReaction(type: TestData.Reactions) -> Self {
        server.websocketReaction(
            type: type,
            eventType: .reactionNew,
            user: participant()
        )
        return self
    }
    
    @discardableResult
    func deleteReaction(type: TestData.Reactions) -> Self {
        server.websocketReaction(
            type: type,
            eventType: .reactionDeleted,
            user: participant()
        )
        return self
    }
    
    @discardableResult
    func replyToMessage(_ text: String) -> Self {
        let quotedMessage = server.lastMessage
        let quotedMessageId = quotedMessage?[MessagePayloadsCodingKeys.id.rawValue] as? String
        server.websocketMessage(
            text,
            channelId: server.currentChannelId,
            messageId: TestData.uniqueId,
            eventType: .messageNew,
            user: participant()
        ) { message in
            message?[MessagePayloadsCodingKeys.quotedMessageId.rawValue] = quotedMessageId
            message?[MessagePayloadsCodingKeys.quotedMessage.rawValue] = quotedMessage
            return message
        }
        return self
    }
    
    @discardableResult
    func replyToMessageInThread(_ text: String, alsoSendInChannel: Bool = false) -> Self {
        let parentId = threadParentId ?? (server.lastMessage?[MessagePayloadsCodingKeys.id.rawValue] as? String)
        server.websocketMessage(
            text,
            channelId: server.currentChannelId,
            messageId: TestData.uniqueId,
            eventType: .messageNew,
            user: participant()
        ) { message in
            message?[MessagePayloadsCodingKeys.parentId.rawValue] = parentId
            message?[MessagePayloadsCodingKeys.showReplyInChannel.rawValue] = alsoSendInChannel
            return message
        }
        return self
    }
    
    @discardableResult
    func sendGiphy() -> Self {
        waitForChannelQueryUpdate()
        server.websocketMessage(
            channelId: server.currentChannelId,
            messageId: TestData.uniqueId,
            messageType: .ephemeral,
            eventType: .messageNew,
            user: participant()
        )
        return self
    }
    
    @discardableResult
    func replyWithGiphy() -> Self {
        let quotedMessage = server.lastMessage
        let quotedMessageId = quotedMessage?[MessagePayloadsCodingKeys.id.rawValue] as? String
        server.websocketMessage(
            channelId: server.currentChannelId,
            messageId: TestData.uniqueId,
            messageType: .ephemeral,
            eventType: .messageNew,
            user: participant()
        ) { message in
            message?[MessagePayloadsCodingKeys.quotedMessageId.rawValue] = quotedMessageId
            message?[MessagePayloadsCodingKeys.quotedMessage.rawValue] = quotedMessage
            return message
        }
        return self
    }
    
    @discardableResult
    func replyWithGiphyInThread(alsoSendInChannel: Bool = false) -> Self {
        let parentId = threadParentId ?? (server.lastMessage?[MessagePayloadsCodingKeys.id.rawValue] as? String)
        server.websocketMessage(
            channelId: server.currentChannelId,
            messageId: TestData.uniqueId,
            messageType: .ephemeral,
            eventType: .messageNew,
            user: participant()
        ) { message in
            message?[MessagePayloadsCodingKeys.parentId.rawValue] = parentId
            message?[MessagePayloadsCodingKeys.showReplyInChannel.rawValue] = alsoSendInChannel
            return message
        }
        return self
    }
    
    private func participant() -> [String: Any]? {
        let json = TestData.toJson(.message)
        guard let message = json[JSONKey.message] as? [String: Any] else {
            return nil
        }

        return server.setUpUser(source: message, details: user)
    }
    
    // To avoid collision of the first channel query call and a first participant's message
    private func waitForChannelQueryUpdate(timeout: Double = 5) {
        let endTime = Date().timeIntervalSince1970 * 1000 + timeout * 1000
        while !server.channelQueryEndpointWasCalled
                && endTime > Date().timeIntervalSince1970 * 1000 {}
    }
}
