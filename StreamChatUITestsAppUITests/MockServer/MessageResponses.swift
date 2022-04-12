//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

extension StreamMockServer {
    
    func configureMessagingEndpoints() {
        server[MockEndpoint.message] = { [weak self] request in
            self?.messageCreation(request: request) ?? .badRequest(nil)
        }
        server[MockEndpoint.messageUpdate] = { [weak self] request in
            self?.messageUpdate(request: request) ?? .badRequest(nil)
        }
        server[MockEndpoint.replies] = { [weak self] request in
            self?.mockMessageReplies(request: request) ?? .badRequest(nil)
        }
    }
    
    func mockDeletedMessage(_ message: [String: Any]) -> [String: Any] {
        var mockedMessage = message
        mockedMessage[MessagePayloadsCodingKeys.deletedAt.rawValue] = TestData.currentDate
        mockedMessage[MessagePayloadsCodingKeys.type.rawValue] = MessageType.deleted.rawValue
        return mockedMessage
    }
    
    func mockMessage(
        _ message: [String: Any],
        messageId: String?,
        text: String?,
        createdAt: String?,
        updatedAt: String?,
        intercept: ((inout [String: Any]) -> [String: Any])? = nil
    ) -> [String: Any] {
        var mockedMessage = message
        mockedMessage[MessagePayloadsCodingKeys.id.rawValue] = messageId
        mockedMessage[MessagePayloadsCodingKeys.createdAt.rawValue] = createdAt
        mockedMessage[MessagePayloadsCodingKeys.updatedAt.rawValue] = updatedAt
        mockedMessage[MessagePayloadsCodingKeys.text.rawValue] = text
        mockedMessage[MessagePayloadsCodingKeys.html.rawValue] = text?.html
        mockedMessage = intercept?(&mockedMessage) ?? mockedMessage
        return mockedMessage
    }
    
    private func messageUpdate(request: HttpRequest) -> HttpResponse {
        if request.method == EndpointMethod.delete.rawValue {
            return messageDeletion(request: request)
        } else {
            return messageCreation(request: request, eventType: .messageUpdated)
        }
    }
    
    private func messageCreation(
        request: HttpRequest,
        eventType: EventType = .messageNew
    ) -> HttpResponse {
        let json = TestData.toJson(request.body)
        let message = json[TopLevelKey.message] as! [String: Any]
        let parentId = message[MessagePayloadsCodingKeys.parentId.rawValue] as? String
        let quotedMessageId = message[MessagePayloadsCodingKeys.quotedMessageId.rawValue] as? String
        
        if let pId = parentId, let qId = quotedMessageId {
            return quotedMessageCreationInThread(message, parentId: pId, quotedMessageId: qId, eventType: eventType)
        } else if let pId = parentId {
            return messageCreationInThread(message, parentId: pId, eventType: eventType)
        } else if let qId = quotedMessageId {
            return quotedMessageCreationInChannel(message, quotedMessageId: qId, eventType: eventType)
        } else {
            return messageCreationInChannel(message, eventType: eventType)
        }
    }
    
    private func messageCreationInChannel(
        _ message: [String: Any],
        eventType: EventType = .messageNew
    ) -> HttpResponse {
        let text = message[MessagePayloadsCodingKeys.text.rawValue] as! String
        let messageId = message[MessagePayloadsCodingKeys.id.rawValue] as! String
        var responseJson = TestData.toJson(.httpMessage)
        let responseMessage = responseJson[TopLevelKey.message] as! [String: Any]
        let timestamp: String = TestData.currentDate
        let user = setUpUser(event: responseMessage, details: UserDetails.lukeSkywalker)
        
        websocketMessage(
            text,
            messageId: messageId,
            timestamp: timestamp,
            eventType: eventType,
            user: user
        )
        
        var mockedMessage = mockMessage(
            responseMessage,
            messageId: messageId,
            text: text,
            createdAt: timestamp,
            updatedAt: timestamp
        )
        
        mockedMessage[MessagePayloadsCodingKeys.user.rawValue] = user
        responseJson[TopLevelKey.message] = mockedMessage
        return .ok(.json(responseJson))
    }
    
    private func quotedMessageCreationInChannel(
        _ message: [String: Any],
        quotedMessageId: String,
        eventType: EventType = .messageNew
    ) -> HttpResponse {
        let text = message[MessagePayloadsCodingKeys.text.rawValue] as! String
        let messageId = message[MessagePayloadsCodingKeys.id.rawValue] as! String
        var responseJson = TestData.toJson(.httpMessage)
        let responseMessage = responseJson[TopLevelKey.message] as! [String: Any]
        let timestamp: String = TestData.currentDate
        let user = setUpUser(event: responseMessage, details: UserDetails.lukeSkywalker)
        let quotedMessage = findMessageById(quotedMessageId)
        
        websocketMessage(
            text,
            messageId: messageId,
            timestamp: timestamp,
            eventType: eventType,
            user: user
        ) { message in
            message[MessagePayloadsCodingKeys.quotedMessageId.rawValue] = quotedMessageId
            message[MessagePayloadsCodingKeys.quotedMessage.rawValue] = quotedMessage
            return message
        }
        
        var mockedMessage = mockMessage(
            responseMessage,
            messageId: messageId,
            text: text,
            createdAt: timestamp,
            updatedAt: timestamp
        ) { message in
            message[MessagePayloadsCodingKeys.quotedMessageId.rawValue] = quotedMessageId
            message[MessagePayloadsCodingKeys.quotedMessage.rawValue] = quotedMessage
            return message
        }
        
        mockedMessage[MessagePayloadsCodingKeys.user.rawValue] = user
        responseJson[TopLevelKey.message] = mockedMessage
        return .ok(.json(responseJson))
    }
    
    private func messageCreationInThread(
        _ message: [String: Any],
        parentId: String,
        eventType: EventType = .messageNew
    ) -> HttpResponse {
        let showInChannel = message[MessagePayloadsCodingKeys.showReplyInChannel.rawValue] as! Bool
        let text = message[MessagePayloadsCodingKeys.text.rawValue] as! String
        let messageId = message[MessagePayloadsCodingKeys.id.rawValue] as! String
        var responseJson = TestData.toJson(.httpMessage)
        let responseMessage = responseJson[TopLevelKey.message] as! [String: Any]
        let timestamp: String = TestData.currentDate
        let user = setUpUser(event: responseMessage, details: UserDetails.lukeSkywalker)
        let parrentMessage = findMessageById(parentId)
        
        websocketMessage(
            parrentMessage[MessagePayloadsCodingKeys.text.rawValue] as! String,
            messageId: parentId,
            timestamp: parrentMessage[MessagePayloadsCodingKeys.createdAt.rawValue] as! String,
            eventType: .messageUpdated,
            user: user
        ) { message in
            message[MessagePayloadsCodingKeys.threadParticipants.rawValue] = [user]
            return message
        }
        
        websocketMessage(
            text,
            messageId: messageId,
            timestamp: timestamp,
            eventType: eventType,
            user: user
        ) { message in
            message[MessagePayloadsCodingKeys.parentId.rawValue] = parentId
            message[MessagePayloadsCodingKeys.showReplyInChannel.rawValue] = showInChannel
            return message
        }
        
        var mockedMessage = mockMessage(
            responseMessage,
            messageId: messageId,
            text: text,
            createdAt: timestamp,
            updatedAt: timestamp
        ) { message in
            message[MessagePayloadsCodingKeys.parentId.rawValue] = parentId
            message[MessagePayloadsCodingKeys.showReplyInChannel.rawValue] = showInChannel
            return message
        }
        
        mockedMessage[MessagePayloadsCodingKeys.user.rawValue] = user
        responseJson[TopLevelKey.message] = mockedMessage
        return .ok(.json(responseJson))
    }
    
    private func quotedMessageCreationInThread(
        _ message: [String: Any],
        parentId: String,
        quotedMessageId: String,
        eventType: EventType = .messageNew
    ) -> HttpResponse {
        let showInChannel = message[MessagePayloadsCodingKeys.showReplyInChannel.rawValue] as! Bool
        let text = message[MessagePayloadsCodingKeys.text.rawValue] as! String
        let messageId = message[MessagePayloadsCodingKeys.id.rawValue] as! String
        var responseJson = TestData.toJson(.httpMessage)
        let responseMessage = responseJson[TopLevelKey.message] as! [String: Any]
        let timestamp: String = TestData.currentDate
        let user = setUpUser(event: responseMessage, details: UserDetails.lukeSkywalker)
        let parrentMessage = findMessageById(parentId)
        let quotedMessage = findMessageById(quotedMessageId)
        
        websocketMessage(
            parrentMessage[MessagePayloadsCodingKeys.text.rawValue] as! String,
            messageId: parentId,
            timestamp: parrentMessage[MessagePayloadsCodingKeys.createdAt.rawValue] as! String,
            eventType: .messageUpdated,
            user: user
        ) { message in
            message[MessagePayloadsCodingKeys.threadParticipants.rawValue] = [user]
            return message
        }
        
        websocketMessage(
            text,
            messageId: messageId,
            timestamp: timestamp,
            eventType: eventType,
            user: user
        ) { message in
            message[MessagePayloadsCodingKeys.parentId.rawValue] = parentId
            message[MessagePayloadsCodingKeys.showReplyInChannel.rawValue] = showInChannel
            message[MessagePayloadsCodingKeys.quotedMessageId.rawValue] = quotedMessageId
            message[MessagePayloadsCodingKeys.quotedMessage.rawValue] = quotedMessage
            return message
        }
        
        var mockedMessage = mockMessage(
            responseMessage,
            messageId: messageId,
            text: text,
            createdAt: timestamp,
            updatedAt: timestamp
        ) { message in
            message[MessagePayloadsCodingKeys.parentId.rawValue] = parentId
            message[MessagePayloadsCodingKeys.showReplyInChannel.rawValue] = showInChannel
            message[MessagePayloadsCodingKeys.quotedMessageId.rawValue] = quotedMessageId
            message[MessagePayloadsCodingKeys.quotedMessage.rawValue] = quotedMessage
            return message
        }
        
        mockedMessage[MessagePayloadsCodingKeys.user.rawValue] = user
        responseJson[TopLevelKey.message] = mockedMessage
        return .ok(.json(responseJson))
    }
    
    private func messageDeletion(request: HttpRequest) -> HttpResponse {
        let messageId = try! XCTUnwrap(request.params[":message_id"])
        var json = TestData.toJson(.httpMessage)
        let message = findMessageById(messageId)
        let timestamp: String = TestData.currentDate
        let user = setUpUser(event: message, details: UserDetails.lukeSkywalker)
        var mockedMessage = mockDeletedMessage(message)
        mockedMessage[MessagePayloadsCodingKeys.user.rawValue] = user
        json[TopLevelKey.message] = mockedMessage
        
        websocketDelay {
            self.websocketMessage(
                messageId: messageId,
                timestamp: timestamp,
                eventType: .messageDeleted,
                user: user
            )
        }
        
        return .ok(.json(json))
    }
    
    private func mockMessageReplies(request: HttpRequest) -> HttpResponse {
        let messageId = try! XCTUnwrap(request.params[":message_id"])
        var json = "{\"\(TopLevelKey.messages)\":[]}".json
        let messages = findMessagesByParrentId(messageId)
        json[TopLevelKey.messages] = messages
        return .ok(.json(json))
    }
}
