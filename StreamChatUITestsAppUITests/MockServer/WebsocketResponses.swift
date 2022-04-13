//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Foundation
import Swifter

extension StreamMockServer {
    
    /// Delays websocket
    ///
    /// - Parameters: Void
    /// - Returns: Self
    func websocketDelay(closure: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            closure()
        }
    }
    
    /// Sends an event over a websocket connection
    ///
    /// - Parameters:
    ///     - EventType
    ///     - [String : Any]: user who triggered an event
    /// - Returns: Self
    @discardableResult
    func websocketEvent(
        _ eventType: EventType,
        user: [String : Any],
        channelId: String
    ) -> Self {
        var json = TestData.getMockResponse(fromFile: .wsChatEvent).json
        json[EventPayload.CodingKeys.user.rawValue] = user
        json[EventPayload.CodingKeys.createdAt.rawValue] = TestData.currentDate
        json[EventPayload.CodingKeys.eventType.rawValue] = eventType.rawValue
        json[EventPayload.CodingKeys.channelId.rawValue] = channelId
        json[EventPayload.CodingKeys.cid.rawValue] = "\(ChannelType.messaging.rawValue):\(channelId)"
        
        writeText(json.jsonToString())
        return self
    }
    
    /// Manages the lifecycle of the messages over a websocket connection
    ///
    /// - Parameters:
    ///     - String: the text that will be used in the message (empty by default for deleted messages)
    ///     - String: messageId that was assigned to the message
    ///     - String: timestamp when the message was created and/or updated
    ///     - EventType: what needs to be done with the message
    ///     - [String : Any]: user who sent the message
    /// - Returns: Self
    @discardableResult
    func websocketMessage(
        _ text: String = "",
        channelId: String,
        messageId: String,
        timestamp: String = TestData.currentDate,
        eventType: EventType,
        user: [String : Any],
        intercept: ((inout [String: Any]) -> [String: Any])? = nil
    ) -> Self {
        var json = TestData.getMockResponse(fromFile: .wsMessage).json
        var mockedMessage: [String: Any]
        
        switch eventType {
        case .messageNew:
            let message = json[TopLevelKey.message] as! [String: Any]
            mockedMessage = mockMessage(
                message,
                channelId: channelId,
                messageId: messageId,
                text: text,
                user: user,
                createdAt: timestamp,
                updatedAt: timestamp
            )
            mockedMessage = intercept?(&mockedMessage) ?? mockedMessage
            saveMessage(mockedMessage)
        case .messageDeleted:
            let message = findMessageById(messageId)
            let id = message[MessagePayloadsCodingKeys.id.rawValue] as! String
            mockedMessage = mockDeletedMessage(message, user: user)
            mockedMessage = intercept?(&mockedMessage) ?? mockedMessage
            removeMessage(id: id)
        case .messageUpdated:
            let message = findMessageById(messageId)
            mockedMessage = mockMessage(
                message,
                channelId: channelId,
                messageId: message[MessagePayloadsCodingKeys.id.rawValue] as! String?,
                text: text,
                user: user,
                createdAt: message[MessagePayloadsCodingKeys.createdAt.rawValue] as! String?,
                updatedAt: timestamp
            )
            mockedMessage = intercept?(&mockedMessage) ?? mockedMessage
            saveMessage(mockedMessage)
        default:
            mockedMessage = [:]
        }
        
        json[TopLevelKey.channelId] = channelId
        json[TopLevelKey.cid] = "\(ChannelType.messaging.rawValue):\(channelId)"
        json[TopLevelKey.user] = user
        json[TopLevelKey.message] = mockedMessage
        json[MessagePayloadsCodingKeys.createdAt.rawValue] = TestData.currentDate
        json[MessagePayloadsCodingKeys.type.rawValue] = eventType.rawValue
        
        writeText(json.jsonToString())
        return self
    }
    
    /// Manages the lifecycle of the reactions over a websocket connection
    ///
    /// - Parameters:
    ///     - TestData.Reactions: the reaction that will be used
    ///     - EventType: what needs to be done with reaction
    ///     - [String : Any]: user who sent the reaction
    /// - Returns: Self
    @discardableResult
    func websocketReaction(
        type: TestData.Reactions,
        eventType: EventType,
        user: [String : Any]
    ) -> Self {
        let messageDetails = lastMessage
        var json = TestData.getMockResponse(fromFile: .wsReaction).json
        var reaction = json[TopLevelKey.reaction] as! [String: Any]
        var message = json[TopLevelKey.message] as! [String: Any]
        let messageId = messageDetails[MessagePayloadsCodingKeys.id.rawValue] as! String
        let cid = messageDetails[MessagePayloadsCodingKeys.cid.rawValue] as! String
        let channelId = cid.split(separator: ":").last
        let timestamp = TestData.currentDate
        
        message = mockMessageWithReaction(
            messageDetails,
            fromUser: user,
            reactionType: type.rawValue,
            timestamp: timestamp,
            deleted: eventType == .reactionDeleted
        )
        
        reaction = mockReaction(
            reaction,
            fromUser: user,
            messageId: messageId,
            reactionType: type.rawValue,
            timestamp: timestamp
        )
        
        json[TopLevelKey.channelId] = channelId
        json[TopLevelKey.cid] = cid
        json[TopLevelKey.message] = message
        json[TopLevelKey.reaction] = reaction
        json[MessageReactionPayload.CodingKeys.user.rawValue] = user
        json[MessageReactionPayload.CodingKeys.createdAt.rawValue] = TestData.currentDate
        json[MessageReactionPayload.CodingKeys.type.rawValue] = eventType.rawValue
        
        writeText(json.jsonToString())
        return self
    }
}
