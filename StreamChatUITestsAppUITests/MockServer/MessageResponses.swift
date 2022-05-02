//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

extension StreamMockServer {
    
    func configureMessagingEndpoints() {
        server.register(MockEndpoint.message) { [weak self] request in
            let channelId = try XCTUnwrap(request.params[EndpointQuery.channelId])
            return self?.messageCreation(request, channelId: channelId)
        }
        server.register(MockEndpoint.messageUpdate) { [weak self] request in
            try self?.messageUpdate(request)
        }
        server.register(MockEndpoint.replies) { [weak self] request in
            let messageId = try XCTUnwrap(request.params[EndpointQuery.messageId])
            return self?.mockMessageReplies(messageId)
        }
    }
    
    func mockDeletedMessage(_ message: [String: Any]?, user: [String: Any]?) -> [String: Any]? {
        var mockedMessage = message
        mockedMessage?[MessagePayloadsCodingKeys.deletedAt.rawValue] = TestData.currentDate
        mockedMessage?[MessagePayloadsCodingKeys.type.rawValue] = MessageType.deleted.rawValue
        mockedMessage?[MessagePayloadsCodingKeys.user.rawValue] = user
        return mockedMessage
    }
    
    func mockMessage(
        _ message: [String: Any]?,
        channelId: String?,
        messageId: String?,
        text: String?,
        user: [String: Any]?,
        createdAt: String?,
        updatedAt: String?
    ) -> [String: Any]? {
        var mockedMessage = message
        mockedMessage?[MessagePayloadsCodingKeys.user.rawValue] = user
        if let createdAt = createdAt, let updatedAt = updatedAt {
            mockedMessage?[MessagePayloadsCodingKeys.createdAt.rawValue] = createdAt
            mockedMessage?[MessagePayloadsCodingKeys.updatedAt.rawValue] = updatedAt
        }
        if let messageId = messageId {
            mockedMessage?[MessagePayloadsCodingKeys.id.rawValue] = messageId
        }
        if let text = text {
            mockedMessage?[MessagePayloadsCodingKeys.text.rawValue] = text
            mockedMessage?[MessagePayloadsCodingKeys.html.rawValue] = text.html
        }
        if let channelId = channelId {
            let channelType = ChannelType.messaging.rawValue
            mockedMessage?[MessagePayloadsCodingKeys.cid.rawValue] = "\(channelType):\(channelId)"
            mockedMessage?[EventPayload.CodingKeys.channelId.rawValue] = channelId
        }
        return mockedMessage
    }
    
    private func messageUpdate(_ request: HttpRequest) throws -> HttpResponse {
        let messageId = try XCTUnwrap(request.params[EndpointQuery.messageId])
        let message = findMessageById(messageId)
        let cid = message?[MessagePayloadsCodingKeys.cid.rawValue] as? String
        let channelId = cid?.split(separator: ":").last.map { String($0) }
        if request.method == EndpointMethod.delete.rawValue {
            return messageDeletion(
                messageId: messageId,
                channelId: channelId
            )
        } else {
            return messageCreation(
                request,
                channelId: channelId,
                eventType: .messageUpdated
            )
        }
    }
    
    private func messageCreation(
        _ request: HttpRequest,
        channelId: String?,
        eventType: EventType = .messageNew
    ) -> HttpResponse {
        let json = TestData.toJson(request.body)
        let message = json[TopLevelKey.message] as? [String: Any]
        let parentId = message?[MessagePayloadsCodingKeys.parentId.rawValue] as? String
        let quotedMessageId = message?[MessagePayloadsCodingKeys.quotedMessageId.rawValue] as? String
        
        if let parentId = parentId, let quotedMessageId = quotedMessageId {
            return quotedMessageCreationInThread(
                message,
                channelId: channelId,
                parentId: parentId,
                quotedMessageId: quotedMessageId,
                eventType: eventType
            )
        } else if let parentId = parentId {
            return messageCreationInThread(
                message,
                channelId: channelId,
                parentId: parentId,
                eventType: eventType
            )
        } else if let quotedMessageId = quotedMessageId {
            return quotedMessageCreationInChannel(
                message,
                channelId: channelId,
                quotedMessageId: quotedMessageId,
                eventType: eventType
            )
        } else {
            return messageCreationInChannel(
                message,
                channelId: channelId,
                eventType: eventType
            )
        }
    }
    
    private func messageCreationInChannel(
        _ message: [String: Any]?,
        channelId: String?,
        eventType: EventType = .messageNew
    ) -> HttpResponse {
        let text = message?[MessagePayloadsCodingKeys.text.rawValue] as? String
        let messageId = message?[MessagePayloadsCodingKeys.id.rawValue] as? String
        var responseJson = TestData.toJson(.httpMessage)
        let responseMessage = responseJson[TopLevelKey.message] as? [String: Any]
        let timestamp: String = TestData.currentDate
        let user = setUpUser(source: responseMessage, details: UserDetails.lukeSkywalker)
        
        websocketMessage(
            text,
            channelId: channelId,
            messageId: messageId,
            timestamp: timestamp,
            eventType: eventType,
            user: user
        )
        
        let mockedMessage = mockMessage(
            responseMessage,
            channelId: channelId,
            messageId: messageId,
            text: text,
            user: user,
            createdAt: timestamp,
            updatedAt: timestamp
        )
        
        responseJson[TopLevelKey.message] = mockedMessage
        return .ok(.json(responseJson))
    }
    
    private func quotedMessageCreationInChannel(
        _ message: [String: Any]?,
        channelId: String?,
        quotedMessageId: String,
        eventType: EventType = .messageNew
    ) -> HttpResponse {
        let text = message?[MessagePayloadsCodingKeys.text.rawValue] as? String
        let messageId = message?[MessagePayloadsCodingKeys.id.rawValue] as? String
        var responseJson = TestData.toJson(.httpMessage)
        let responseMessage = responseJson[TopLevelKey.message] as? [String: Any]
        let timestamp: String = TestData.currentDate
        let user = setUpUser(source: responseMessage, details: UserDetails.lukeSkywalker)
        let quotedMessage = findMessageById(quotedMessageId)
        
        websocketMessage(
            text,
            channelId: channelId,
            messageId: messageId,
            timestamp: timestamp,
            eventType: eventType,
            user: user
        ) { message in
            message?[MessagePayloadsCodingKeys.quotedMessageId.rawValue] = quotedMessageId
            message?[MessagePayloadsCodingKeys.quotedMessage.rawValue] = quotedMessage
            return message
        }
        
        var mockedMessage = mockMessage(
            responseMessage,
            channelId: channelId,
            messageId: messageId,
            text: text,
            user: user,
            createdAt: timestamp,
            updatedAt: timestamp
        )
        mockedMessage?[MessagePayloadsCodingKeys.quotedMessageId.rawValue] = quotedMessageId
        mockedMessage?[MessagePayloadsCodingKeys.quotedMessage.rawValue] = quotedMessage
        
        responseJson[TopLevelKey.message] = mockedMessage
        return .ok(.json(responseJson))
    }
    
    private func messageCreationInThread(
        _ message: [String: Any]?,
        channelId: String?,
        parentId: String,
        eventType: EventType = .messageNew
    ) -> HttpResponse {
        let showInChannel = message?[MessagePayloadsCodingKeys.showReplyInChannel.rawValue] as? Bool
        let text = message?[MessagePayloadsCodingKeys.text.rawValue] as? String
        let messageId = message?[MessagePayloadsCodingKeys.id.rawValue] as? String
        var responseJson = TestData.toJson(.httpMessage)
        let responseMessage = responseJson[TopLevelKey.message] as? [String: Any]
        let timestamp: String = TestData.currentDate
        let user = setUpUser(source: responseMessage, details: UserDetails.lukeSkywalker)
        let parrentMessage = findMessageById(parentId)
        
        websocketMessage(
            parrentMessage?[MessagePayloadsCodingKeys.text.rawValue] as? String,
            channelId: channelId,
            messageId: parentId,
            timestamp: parrentMessage?[MessagePayloadsCodingKeys.createdAt.rawValue] as? String,
            eventType: .messageUpdated,
            user: user
        ) { message in
            message?[MessagePayloadsCodingKeys.threadParticipants.rawValue] = [user]
            return message
        }
        
        websocketMessage(
            text,
            channelId: channelId,
            messageId: messageId,
            timestamp: timestamp,
            eventType: eventType,
            user: user
        ) { message in
            message?[MessagePayloadsCodingKeys.parentId.rawValue] = parentId
            message?[MessagePayloadsCodingKeys.showReplyInChannel.rawValue] = showInChannel
            return message
        }
        
        var mockedMessage = mockMessage(
            responseMessage,
            channelId: channelId,
            messageId: messageId,
            text: text,
            user: user,
            createdAt: timestamp,
            updatedAt: timestamp
        )
        mockedMessage?[MessagePayloadsCodingKeys.parentId.rawValue] = parentId
        mockedMessage?[MessagePayloadsCodingKeys.showReplyInChannel.rawValue] = showInChannel
        
        responseJson[TopLevelKey.message] = mockedMessage
        return .ok(.json(responseJson))
    }
    
    private func quotedMessageCreationInThread(
        _ message: [String: Any]?,
        channelId: String?,
        parentId: String,
        quotedMessageId: String,
        eventType: EventType = .messageNew
    ) -> HttpResponse {
        let showInChannel = message?[MessagePayloadsCodingKeys.showReplyInChannel.rawValue] as? Bool
        let text = message?[MessagePayloadsCodingKeys.text.rawValue] as? String
        let messageId = message?[MessagePayloadsCodingKeys.id.rawValue] as? String
        var responseJson = TestData.toJson(.httpMessage)
        let responseMessage = responseJson[TopLevelKey.message] as? [String: Any]
        let timestamp: String = TestData.currentDate
        let user = setUpUser(source: responseMessage, details: UserDetails.lukeSkywalker)
        let parrentMessage = findMessageById(parentId)
        let quotedMessage = findMessageById(quotedMessageId)
        
        websocketMessage(
            parrentMessage?[MessagePayloadsCodingKeys.text.rawValue] as? String,
            channelId: channelId,
            messageId: parentId,
            timestamp: parrentMessage?[MessagePayloadsCodingKeys.createdAt.rawValue] as? String,
            eventType: .messageUpdated,
            user: user
        ) { message in
            message?[MessagePayloadsCodingKeys.threadParticipants.rawValue] = [user]
            return message
        }
        
        websocketMessage(
            text,
            channelId: channelId,
            messageId: messageId,
            timestamp: timestamp,
            eventType: eventType,
            user: user
        ) { message in
            message?[MessagePayloadsCodingKeys.parentId.rawValue] = parentId
            message?[MessagePayloadsCodingKeys.showReplyInChannel.rawValue] = showInChannel
            message?[MessagePayloadsCodingKeys.quotedMessageId.rawValue] = quotedMessageId
            message?[MessagePayloadsCodingKeys.quotedMessage.rawValue] = quotedMessage
            return message
        }
        
        var mockedMessage = mockMessage(
            responseMessage,
            channelId: channelId,
            messageId: messageId,
            text: text,
            user: user,
            createdAt: timestamp,
            updatedAt: timestamp
        )
        mockedMessage?[MessagePayloadsCodingKeys.parentId.rawValue] = parentId
        mockedMessage?[MessagePayloadsCodingKeys.showReplyInChannel.rawValue] = showInChannel
        mockedMessage?[MessagePayloadsCodingKeys.quotedMessageId.rawValue] = quotedMessageId
        mockedMessage?[MessagePayloadsCodingKeys.quotedMessage.rawValue] = quotedMessage
        
        responseJson[TopLevelKey.message] = mockedMessage
        return .ok(.json(responseJson))
    }
    
    private func messageDeletion(messageId: String, channelId: String?) -> HttpResponse {
        var json = TestData.toJson(.httpMessage)
        let message = findMessageById(messageId)
        let timestamp: String = TestData.currentDate
        let user = setUpUser(source: message, details: UserDetails.lukeSkywalker)
        let mockedMessage = mockDeletedMessage(message, user: user)
        
        websocketMessage(
            channelId: channelId,
            messageId: messageId,
            timestamp: timestamp,
            eventType: .messageDeleted,
            user: user
        )
        
        json[TopLevelKey.message] = mockedMessage
        return .ok(.json(json))
    }
    
    private func mockMessageReplies(_ messageId: String) -> HttpResponse {
        var json = "{\"\(TopLevelKey.messages)\":[]}".json
        let messages = findMessagesByParrentId(messageId)
        json[TopLevelKey.messages] = messages
        return .ok(.json(json))
    }
}
