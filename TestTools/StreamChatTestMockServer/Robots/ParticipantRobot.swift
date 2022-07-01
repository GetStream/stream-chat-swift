//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

public class ParticipantRobot {

    private var server: StreamMockServer
    private var threadParentId: String?
    private var user: [String: String] = UserDetails.hanSolo
    
    public init(_ server: StreamMockServer) {
        self.server = server
    }

    public var currentUserId: String {
        UserDetails.userId(for: user)
    }
    
    @discardableResult
    public func startTyping() -> Self {
        server.websocketEvent(
            .userStartTyping,
            user: participant(),
            channelId: server.currentChannelId
        )
        return self
    }
    
    @discardableResult
    public func startTypingInThread() -> Self {
        let parentId = threadParentId ?? (server.lastMessage?[MessagePayloadsCodingKeys.id.rawValue] as? String)
        server.websocketEvent(
            .userStartTyping,
            user: participant(),
            channelId: server.currentChannelId,
            parentMessageId: parentId
        )
        return self
    }
    
    @discardableResult
    public func stopTyping() -> Self {
        server.websocketEvent(
            .userStopTyping,
            user: participant(),
            channelId: server.currentChannelId
        )
        return self
    }
    
    @discardableResult
    public func stopTypingInThread() -> Self {
        let parentId = threadParentId ?? (server.lastMessage?[MessagePayloadsCodingKeys.id.rawValue] as? String)
        server.websocketEvent(
            .userStopTyping,
            user: participant(),
            channelId: server.currentChannelId,
            parentMessageId: parentId
        )
        return self
    }
    
    // Sleep in seconds
    @discardableResult
    public func wait(_ duration: TimeInterval) -> Self {
        let sleepTime = UInt32(duration * 1000000)
        usleep(sleepTime)
        return self
    }
    
    @discardableResult
    public func readMessage() -> Self {
        server.waitForChannelsUpdate()
        
        server.websocketEvent(
            .messageRead,
            user: participant(),
            channelId: server.currentChannelId
        )
        return self
    }
    
    @discardableResult
    public func sendMessage(_ text: String,
                            waitForAppearance: Bool = true,
                            waitForChannelQuery: Bool = true,
                            waitBeforeSending: TimeInterval = 0,
                            file: StaticString = #filePath,
                            line: UInt = #line) -> Self {
        if waitBeforeSending > 0 {
            wait(waitBeforeSending)
        }
        
        if waitForChannelQuery {
            server.waitForChannelQueryUpdate()
        }
        
        startTyping()
        stopTyping()
        
        server.websocketMessage(
            text,
            channelId: server.currentChannelId,
            messageId: TestData.uniqueId,
            eventType: .messageNew,
            user: participant()
        )
        
        if waitForAppearance {
            server.waitForWebsocketMessage(withText: text)
        }
        return self
    }

    /// The given text will be decorated with the index, eg "message-10"
    @discardableResult
    public func sendMultipleMessages(repeatingText text: String, count: Int) -> Self {
        var texts = [String]()
        for index in 1...count {
            texts.append("\(text)-\(index)")
        }

        texts.forEach {
            sendMessage($0, waitForAppearance: false)
            wait(0.3)
        }
        return self
    }
    
    @discardableResult
    public func editMessage(_ text: String) -> Self {
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
    public func deleteMessage() -> Self {
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
    public func addReaction(type: TestData.Reactions) -> Self {
        server.websocketReaction(
            type: type,
            eventType: .reactionNew,
            user: participant()
        )
        return self
    }
    
    @discardableResult
    public func deleteReaction(type: TestData.Reactions) -> Self {
        server.websocketReaction(
            type: type,
            eventType: .reactionDeleted,
            user: participant()
        )
        return self
    }
    
    @discardableResult
    public func replyToMessage(_ text: String) -> Self {
        startTyping()
        stopTyping()
        
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
    public func replyToMessageInThread(_ text: String, alsoSendInChannel: Bool = false) -> Self {
        startTypingInThread()
        stopTypingInThread()
        
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
    public func sendGiphy(waitForChannelQuery: Bool = true, waitBeforeSending: TimeInterval = 0) -> Self {
        if waitBeforeSending > 0 {
            wait(waitBeforeSending)
        }
        
        if waitForChannelQuery {
            server.waitForChannelQueryUpdate()
        }
        
        startTyping()
        stopTyping()
        
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
    public func replyWithGiphy() -> Self {
        startTyping()
        stopTyping()
        
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
    public func replyWithGiphyInThread(alsoSendInChannel: Bool = false) -> Self {
        startTypingInThread()
        stopTypingInThread()
        
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
    
    @discardableResult
    public func uploadAttachment(type: AttachmentType,
                                 count: Int = 1,
                                 waitForAppearance: Bool = true,
                                 waitForChannelQuery: Bool = true,
                                 waitBeforeSending: TimeInterval = 0,
                                 file: StaticString = #filePath,
                                 line: UInt = #line) -> Self {
        if waitBeforeSending > 0 {
            wait(waitBeforeSending)
        }
        
        if waitForChannelQuery {
            server.waitForChannelQueryUpdate()
        }
        
        startTyping()
        stopTyping()
        
        server.websocketMessage(
            channelId: server.currentChannelId,
            messageId: TestData.uniqueId,
            eventType: .messageNew,
            user: participant()
        ) { message in
            var attachments: [[String: Any]] = []
            var file: [String: Any] = [:]
            file[AttachmentCodingKeys.type.rawValue] = type.rawValue
            
            switch type {
            case .image:
                file[AttachmentCodingKeys.imageURL.rawValue] = Attachments.image
            case .video:
                file[AttachmentCodingKeys.assetURL.rawValue] = Attachments.video
                file[AttachmentFile.CodingKeys.mimeType.rawValue] = "video/mp4"
            default:
                file[AttachmentCodingKeys.assetURL.rawValue] = Attachments.file
                file[AttachmentFile.CodingKeys.mimeType.rawValue] = "application/pdf"
            }
            
            if type != .image {
                file[AttachmentFile.CodingKeys.size.rawValue] = 123456
            }
                
            for i in 1...count {
                file[AttachmentCodingKeys.title.rawValue] = "\(type.rawValue)_\(i)"
                attachments.append(file)
            }
            
            message?[MessagePayloadsCodingKeys.attachments.rawValue] = attachments
            return message
        }
        
        if waitForAppearance {
            server.waitForWebsocketMessage(withText: "")
        }
        return self
    }
}
