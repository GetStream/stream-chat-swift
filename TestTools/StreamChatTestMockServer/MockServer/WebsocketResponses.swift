//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Foundation
import Swifter
import StreamChatTestHelpers

public extension StreamMockServer {

    /// Sends an event over a websocket connection
    ///
    /// - Parameters:
    ///     - EventType
    ///     - [String : Any]: user who triggered an event
    /// - Returns: Self
    @discardableResult
    func websocketEvent(
        _ eventType: EventType,
        user: [String: Any]?,
        channelId: String
    ) -> Self {
        let json = websocketEventJSON(eventType, user: user, channelId: channelId)
        writeText(json.jsonToString())
        return self
    }

    private func websocketEventJSON(_ eventType: EventType, user: [String: Any]?, channelId: String) -> [String: Any] {
        var json = TestData.getMockResponse(fromFile: .wsChatEvent).json
        json[EventPayload.CodingKeys.user.rawValue] = user
        json[EventPayload.CodingKeys.createdAt.rawValue] = TestData.currentDate
        json[EventPayload.CodingKeys.eventType.rawValue] = eventType.rawValue
        json[EventPayload.CodingKeys.channelId.rawValue] = channelId
        json[EventPayload.CodingKeys.channelType.rawValue] = ChannelType.messaging.rawValue
        json[EventPayload.CodingKeys.cid.rawValue] = "\(ChannelType.messaging.rawValue):\(channelId)"
        return json
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
        _ text: String? = "",
        channelId: String?,
        messageId: String?,
        timestamp: String? = TestData.currentDate,
        messageType: MessageType = .regular,
        eventType: EventType,
        user: [String: Any]?,
        intercept: ((inout [String: Any]?) -> [String: Any]?)? = nil
    ) -> Self {
        guard let messageId = messageId else { return self }
        
        let mockFile = messageType == .ephemeral ? MockFile.ephemeralMessage : MockFile.message
        var json = TestData.getMockResponse(fromFile: mockFile).json
        var mockedMessage: [String: Any]?
        
        switch eventType {
        case .messageNew:
            var message = json[JSONKey.message] as? [String: Any]
            if messageType == .ephemeral {
                var attachments = message?[MessagePayloadsCodingKeys.attachments.rawValue] as? [[String: Any]]
                attachments?[0][GiphyAttachmentSpecificCodingKeys.actions.rawValue] = nil
                message?[MessagePayloadsCodingKeys.attachments.rawValue] = attachments
                message?[MessagePayloadsCodingKeys.type.rawValue] = MessageType.regular.rawValue
            }
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
            mockedMessage = mockDeletedMessage(message, user: user)
            mockedMessage = intercept?(&mockedMessage) ?? mockedMessage
            saveMessage(mockedMessage)
        case .messageUpdated:
            let message = findMessageById(messageId)
            mockedMessage = mockMessage(
                message,
                channelId: channelId,
                messageId: message?[MessagePayloadsCodingKeys.id.rawValue] as? String,
                text: text,
                user: user,
                createdAt: message?[MessagePayloadsCodingKeys.createdAt.rawValue] as? String,
                updatedAt: timestamp
            )
            mockedMessage = intercept?(&mockedMessage) ?? mockedMessage
            saveMessage(mockedMessage)
        default:
            mockedMessage = [:]
        }
        
        if let channelId = channelId {
            json[JSONKey.channelId] = channelId
            json[JSONKey.channelType] = ChannelType.messaging.rawValue
            json[JSONKey.cid] = "\(ChannelType.messaging.rawValue):\(channelId)"
        }
        
        json[JSONKey.user] = user
        json[JSONKey.message] = mockedMessage
        json[MessagePayloadsCodingKeys.createdAt.rawValue] = TestData.currentDate
        json[MessagePayloadsCodingKeys.type.rawValue] = eventType.rawValue
        
        writeText(json.jsonToString())
        if eventType == .messageNew { latestWebsocketMessage = text ?? "" }
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
        type: TestData.Reactions?,
        eventType: EventType,
        user: [String: Any]?
    ) -> Self {
        let messageDetails = lastMessage
        var json = TestData.getMockResponse(fromFile: .wsReaction).json
        var reaction = json[JSONKey.reaction] as? [String: Any]
        var message = json[JSONKey.message] as? [String: Any]
        let messageId = messageDetails?[MessagePayloadsCodingKeys.id.rawValue] as? String
        let cid = messageDetails?[MessagePayloadsCodingKeys.cid.rawValue] as? String
        let channelId = cid?.split(separator: ":").last
        let timestamp = TestData.currentDate
        
        message = mockMessageWithReaction(
            messageDetails,
            fromUser: user,
            reactionType: type?.rawValue,
            timestamp: timestamp,
            deleted: eventType == .reactionDeleted
        )
        
        reaction = mockReaction(
            reaction,
            fromUser: user,
            messageId: messageId,
            reactionType: type?.rawValue,
            timestamp: timestamp
        )
        
        json[JSONKey.channelId] = channelId
        json[JSONKey.cid] = cid
        json[JSONKey.message] = message
        json[JSONKey.reaction] = reaction
        json[MessageReactionPayload.CodingKeys.user.rawValue] = user
        json[MessageReactionPayload.CodingKeys.createdAt.rawValue] = TestData.currentDate
        json[MessageReactionPayload.CodingKeys.type.rawValue] = eventType.rawValue
        
        saveMessage(message)
        writeText(json.jsonToString())
        return self
    }
}

// MARK: Channel Members

public extension StreamMockServer {

    /// Adds new members to channel
    ///
    /// - Parameters:
    ///     - members: json representation of members
    ///     - channelId: channel id
    ///     - timestamp: event timestamp
    ///     - EventType: what needs to be done with the message
    ///     - user: user who created the channel
    /// - Returns: Self
    @discardableResult
    func websocketChannelUpdated(
        with members: [[String: Any]],
        channelId: String,
        timestamp: String? = TestData.currentDate
    ) -> Self {
        var json = TestData.getMockResponse(fromFile: .wsChannelEvent).json

        // updated config with current values
        updateConfig(in: &json, withId: channelId)
        
        json[JSONKey.channelId] = channelId
        json[JSONKey.cid] = "\(ChannelType.messaging.rawValue):\(channelId)"
        json[JSONKey.channelType] = ChannelType.messaging.rawValue
        json[JSONKey.createdAt] = TestData.currentDate
        json[JSONKey.eventType] = EventType.channelUpdated.rawValue
        json[JSONKey.user] = setUpUser(source: json, details: UserDetails.lukeSkywalker)

        if var channel = json[JSONKey.channel] as? [String: Any] {
            channel[JSONKey.members] = members
            channel[ChannelCodingKeys.memberCount.rawValue] = members.count

            json[ChannelCodingKeys.members.rawValue] = members
            json[ChannelCodingKeys.memberCount.rawValue] = members.count
            json[JSONKey.channel] = channel
        }

        writeText(json.jsonToString())
        return self
    }

    /// Events: member.added, member.updatem member.removed
    ///
    /// - Parameters:
    ///     - member: json representation of member
    ///     - channelId: channel id
    ///     - timestamp: event timestamp
    ///     - EventType: what needs to be done with the message
    /// - Returns: Self
    @discardableResult
    func websocketMember(
        with member: [String: Any],
        channelId: String,
        timestamp: String? = TestData.currentDate,
        eventType: EventType
    ) -> Self {
        var json = TestData.getMockResponse(fromFile: .wsMemberEvent).json
        json[JSONKey.channelId] = channelId
        json[JSONKey.cid] = "\(ChannelType.messaging.rawValue):\(channelId)"
        json[JSONKey.channelType] = ChannelType.messaging.rawValue
        json[JSONKey.createdAt] = TestData.currentDate
        json[JSONKey.eventType] = eventType.rawValue
        json[JSONKey.member] = member
        json[JSONKey.user] = member[JSONKey.user]

        writeText(json.jsonToString())
        return self
    }
}
