//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

/// Simulates participant behavior
final class ParticipantRobot: Robot {

    private var server: StreamMockServer
    
    init(_ server: StreamMockServer) {
        self.server = server
    }
    
    @discardableResult
    func startTyping() -> Self {
        sendEvent(.userStartTyping)
        return self
    }
    
    @discardableResult
    func stopTyping() -> Self {
        sendEvent(.userStopTyping)
        return self
    }
    
    @discardableResult
    func readMessage() -> Self {
        sendEvent(.messageRead)
        return self
    }
    
    @discardableResult
    func sendMessage(_ text: String) -> Self {
        message(text, eventType: .messageNew)
    }
    
    @discardableResult
    func editMessage(_ text: String) -> Self {
        message(text, eventType: .messageUpdated)
    }
    
    @discardableResult
    func deleteMessage() -> Self {
        message(eventType: .messageDeleted)
    }
    
    @discardableResult
    func addReaction(type: TestData.Reactions) -> Self {
        sendReaction(type: type, eventType: .reactionNew)
    }
    
    @discardableResult
    func deleteReaction(type: TestData.Reactions) -> Self {
        sendReaction(type: type, eventType: .reactionDeleted)
    }
    
    // TODO: CIS-1685
    @discardableResult
    func replyToMessage(_ text: String) -> Self {
        return self
    }
    
    // TODO: CIS-1685
    @discardableResult
    func replyToMessageInThread(_ text: String, alsoSendInChannel: Bool = false) -> Self {
        return self
    }
    
    /// Sends an event over a websocket connection
    ///
    /// - Parameters: EventType
    /// - Returns: Self
    @discardableResult
    private func sendEvent(_ eventType: EventType) -> Self {
        var json = TestData.getMockResponse(fromFile: .wsChatEvent).json
        json[TopLevelKey.createdAt.rawValue] = TestData.currentDate
        json[TopLevelKey.type.rawValue] = eventType.rawValue
        server.writeText(json.jsonToString())
        return self
    }
    
    /// Manages the lifecycle of the messages over a websocket connection
    ///
    /// - Parameters:
    ///     - String: the text that will be used in the message (empty by default for deleted messages)
    ///     - EventType: what needs to be done with message
    /// - Returns: Self
    @discardableResult
    private func message(_ text: String = "", eventType: EventType) -> Self {
        var json = TestData.getMockResponse(fromFile: .wsMessage).json
        let messageKey = TopLevelKey.message.rawValue
        let message = json[messageKey] as! Dictionary<String, Any>
        let timestamp: String = TestData.currentDate
        
        switch eventType {
        case .messageNew:
            let messageId = TestData.uniqueId
            json[messageKey] = server.mockMessage(
                message,
                messageId: messageId,
                text: text,
                createdAt: timestamp,
                updatedAt: timestamp,
                saveDetails: true
            )
        case .messageDeleted:
            let messageDetails = server.getMessageDetails()
            json[messageKey] = server.mockMessage(
                message,
                messageId: messageDetails[.messageId],
                text: messageDetails[.text],
                createdAt: messageDetails[.createdAt],
                updatedAt: timestamp,
                deleted: true
            )
        case .messageUpdated:
            let messageDetails = server.getMessageDetails()
            json[messageKey] = server.mockMessage(
                message,
                messageId: messageDetails[.messageId],
                text: text,
                createdAt: messageDetails[.createdAt],
                updatedAt: timestamp,
                saveDetails: true
            )
        default:
            json[messageKey] = [:]
        }
        
        json[TopLevelKey.type.rawValue] = eventType.rawValue
        server.writeText(json.jsonToString())
        return self
    }
    
    /// Manages the lifecycle of the reactions over a websocket connection
    ///
    /// - Parameters:
    ///     - TestData.Reactions: the reaction that will be used
    ///     - EventType: what needs to be done with reaction
    /// - Returns: Self
    @discardableResult
    private func sendReaction(type: TestData.Reactions, eventType: EventType) -> Self {
        let messageDetails = server.getMessageDetails()
        var json = TestData.getMockResponse(fromFile: .wsReaction).json
        let messageKey = TopLevelKey.message.rawValue
        let reactionKey = TopLevelKey.reaction.rawValue
        var reaction = json[reactionKey] as! Dictionary<String, Any>
        var message = json[messageKey] as! Dictionary<String, Any>
        let messageId = messageDetails[.messageId]
        let timestamp = TestData.currentDate
        
        message = server.mockMessageWithReaction(
            message,
            messageId: messageId,
            text: messageDetails[.text],
            createdAt: messageDetails[.createdAt],
            updatedAt: messageDetails[.updatedAt],
            reactionType: type.rawValue,
            deleted: eventType == .reactionDeleted
        )
        
        reaction = server.mockReaction(
            reaction,
            messageId: messageId,
            reactionType: type.rawValue,
            timestamp: timestamp
        )
        
        json[messageKey] = message
        json[reactionKey] = reaction
        json[TopLevelKey.type.rawValue] = eventType.rawValue
        
        server.writeText(json.jsonToString())
        return self
    }
}
