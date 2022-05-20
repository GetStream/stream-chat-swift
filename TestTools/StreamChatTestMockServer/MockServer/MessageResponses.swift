//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

public let messageKey = MessagePayloadsCodingKeys.self

public extension StreamMockServer {
    
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
        mockedMessage?[messageKey.deletedAt.rawValue] = TestData.currentDate
        mockedMessage?[messageKey.type.rawValue] = MessageType.deleted.rawValue
        mockedMessage?[messageKey.user.rawValue] = user
        return mockedMessage
    }
    
    func mockMessage(
        _ message: [String: Any]?,
        channelId: String?,
        messageId: String?,
        text: String?,
        command: String? = nil,
        type: MessageType = .regular,
        user: [String: Any]?,
        createdAt: String?,
        updatedAt: String?
    ) -> [String: Any]? {
        var mockedMessage = message
        mockedMessage?[messageKey.user.rawValue] = user
        mockedMessage?[messageKey.type.rawValue] = type.rawValue
        if let createdAt = createdAt, let updatedAt = updatedAt {
            mockedMessage?[messageKey.createdAt.rawValue] = createdAt
            mockedMessage?[messageKey.updatedAt.rawValue] = updatedAt
        }
        if let messageId = messageId {
            mockedMessage?[messageKey.id.rawValue] = messageId
        }
        if let text = text {
            mockedMessage?[messageKey.text.rawValue] = text
            mockedMessage?[messageKey.html.rawValue] = text.html
        }
        if let command = command {
            mockedMessage?[messageKey.command.rawValue] = command
        }
        if let channelId = channelId {
            let channelType = ChannelType.messaging.rawValue
            mockedMessage?[messageKey.cid.rawValue] = "\(channelType):\(channelId)"
            mockedMessage?[EventPayload.CodingKeys.channelId.rawValue] = channelId
        }
        return mockedMessage
    }
    
    private func messageUpdate(_ request: HttpRequest) throws -> HttpResponse {
        let messageId = try XCTUnwrap(request.params[EndpointQuery.messageId])
        let message = findMessageById(messageId)
        let cid = message?[messageKey.cid.rawValue] as? String
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
        let message = json[JSONKey.message] as? [String: Any]
        let parentId = message?[messageKey.parentId.rawValue] as? String
        let quotedMessageId = message?[messageKey.quotedMessageId.rawValue] as? String
        if
            let messageText = message?[messageKey.text.rawValue] as? String,
            messageText.count > 2 {
            let index = messageText.index(messageText.startIndex, offsetBy: 2)
            if messageText.prefix(upTo: index).contains("/") {
                return messageInvalidCommand(message,
                                         command: String(messageText.dropFirst(1)),
                                         channelId: channelId)
            }
        }
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
        let text = message?[messageKey.text.rawValue] as? String
        let messageId = message?[messageKey.id.rawValue] as? String
        var responseJson = TestData.toJson(.httpMessage)
        let responseMessage = responseJson[JSONKey.message] as? [String: Any]
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
        
        responseJson[JSONKey.message] = mockedMessage
        return .ok(.json(responseJson))
    }
    
    private func quotedMessageCreationInChannel(
        _ message: [String: Any]?,
        channelId: String?,
        quotedMessageId: String,
        eventType: EventType = .messageNew
    ) -> HttpResponse {
        let text = message?[messageKey.text.rawValue] as? String
        let messageId = message?[messageKey.id.rawValue] as? String
        var responseJson = TestData.toJson(.httpMessage)
        let responseMessage = responseJson[JSONKey.message] as? [String: Any]
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
            message?[messageKey.quotedMessageId.rawValue] = quotedMessageId
            message?[messageKey.quotedMessage.rawValue] = quotedMessage
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
        mockedMessage?[messageKey.quotedMessageId.rawValue] = quotedMessageId
        mockedMessage?[messageKey.quotedMessage.rawValue] = quotedMessage
        
        responseJson[JSONKey.message] = mockedMessage
        return .ok(.json(responseJson))
    }
    
    private func messageCreationInThread(
        _ message: [String: Any]?,
        channelId: String?,
        parentId: String,
        eventType: EventType = .messageNew
    ) -> HttpResponse {
        let showInChannel = message?[messageKey.showReplyInChannel.rawValue] as? Bool
        let text = message?[messageKey.text.rawValue] as? String
        let messageId = message?[messageKey.id.rawValue] as? String
        var responseJson = TestData.toJson(.httpMessage)
        let responseMessage = responseJson[JSONKey.message] as? [String: Any]
        let timestamp: String = TestData.currentDate
        let user = setUpUser(source: responseMessage, details: UserDetails.lukeSkywalker)
        let parentMessage = findMessageById(parentId)
        
        websocketMessage(
            parentMessage?[messageKey.text.rawValue] as? String,
            channelId: channelId,
            messageId: parentId,
            timestamp: parentMessage?[messageKey.createdAt.rawValue] as? String,
            eventType: .messageUpdated,
            user: parentMessage?[JSONKey.user] as? [String: Any]
        ) { message in
            message?[messageKey.threadParticipants.rawValue] = [user]
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
            message?[messageKey.parentId.rawValue] = parentId
            message?[messageKey.showReplyInChannel.rawValue] = showInChannel
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
        mockedMessage?[messageKey.parentId.rawValue] = parentId
        mockedMessage?[messageKey.showReplyInChannel.rawValue] = showInChannel
        
        responseJson[JSONKey.message] = mockedMessage
        return .ok(.json(responseJson))
    }
    
    private func quotedMessageCreationInThread(
        _ message: [String: Any]?,
        channelId: String?,
        parentId: String,
        quotedMessageId: String,
        eventType: EventType = .messageNew
    ) -> HttpResponse {
        let showInChannel = message?[messageKey.showReplyInChannel.rawValue] as? Bool
        let text = message?[messageKey.text.rawValue] as? String
        let messageId = message?[messageKey.id.rawValue] as? String
        var responseJson = TestData.toJson(.httpMessage)
        let responseMessage = responseJson[JSONKey.message] as? [String: Any]
        let timestamp: String = TestData.currentDate
        let user = setUpUser(source: responseMessage, details: UserDetails.lukeSkywalker)
        let parrentMessage = findMessageById(parentId)
        let quotedMessage = findMessageById(quotedMessageId)
        
        websocketMessage(
            parrentMessage?[messageKey.text.rawValue] as? String,
            channelId: channelId,
            messageId: parentId,
            timestamp: parrentMessage?[messageKey.createdAt.rawValue] as? String,
            eventType: .messageUpdated,
            user: user
        ) { message in
            message?[messageKey.threadParticipants.rawValue] = [user]
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
            message?[messageKey.parentId.rawValue] = parentId
            message?[messageKey.showReplyInChannel.rawValue] = showInChannel
            message?[messageKey.quotedMessageId.rawValue] = quotedMessageId
            message?[messageKey.quotedMessage.rawValue] = quotedMessage
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
        mockedMessage?[messageKey.parentId.rawValue] = parentId
        mockedMessage?[messageKey.showReplyInChannel.rawValue] = showInChannel
        mockedMessage?[messageKey.quotedMessageId.rawValue] = quotedMessageId
        mockedMessage?[messageKey.quotedMessage.rawValue] = quotedMessage
        
        responseJson[JSONKey.message] = mockedMessage
        return .ok(.json(responseJson))
    }
    
    private func messageDeletion(messageId: String, channelId: String?) -> HttpResponse {
        var json = TestData.toJson(.httpMessage)
        let message = findMessageById(messageId)
        let timestamp: String = TestData.currentDate
        let user = message?[JSONKey.user] as? [String: Any]
        let mockedMessage = mockDeletedMessage(message, user: user)
        
        websocketDelay { [weak self] in
            self?.websocketMessage(
                channelId: channelId,
                messageId: messageId,
                timestamp: timestamp,
                eventType: .messageDeleted,
                user: user
            )
        }
        
        json[JSONKey.message] = mockedMessage
        return .ok(.json(json))
    }
    
    private func mockMessageReplies(_ messageId: String) -> HttpResponse {
        var json = "{\"\(JSONKey.messages)\":[]}".json
        let messages = findMessagesByParrentId(messageId)
        json[JSONKey.messages] = messages
        return .ok(.json(json))
    }

    private func messageInvalidCommand(
        _ message: [String: Any]?,
        command: String,
        channelId: String?,
        eventType: EventType = .messageRead
    ) -> HttpResponse {
        let text = Message.message(withInvalidCommand: command)
        let messageId = message?[messageKey.id.rawValue] as? String
        var responseJson = TestData.toJson(.httpMessage)
        let responseMessage = responseJson[JSONKey.message] as? [String: Any]
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
            command: command,
            type: .error,
            user: user,
            createdAt: timestamp,
            updatedAt: timestamp
        )

        responseJson[JSONKey.message] = mockedMessage
        return .ok(.json(responseJson))
    }
}
