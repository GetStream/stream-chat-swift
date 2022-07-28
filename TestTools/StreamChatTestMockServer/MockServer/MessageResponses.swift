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
        server.register(MockEndpoint.action) { [weak self] request in
            let json = TestData.toJson(request.body)
            let messageId = json[AttachmentActionRequestBody.CodingKeys.messageId.rawValue] as? String
            let channelId = json[AttachmentActionRequestBody.CodingKeys.channelId.rawValue] as? String
            let formData = json[AttachmentActionRequestBody.CodingKeys.data.rawValue] as? [String: Any]
            return self?.ephemeralMessageCreation(messageId: try XCTUnwrap(messageId),
                                                  channelId: try XCTUnwrap(channelId),
                                                  formData: try XCTUnwrap(formData))
        }
    }
    
    private func trackMessage(_ text: String,
                              messageType: MessageType,
                              eventType: EventType) {
        if eventType == .messageNew && messageType != .ephemeral {
            latestHttpMessage = text
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
        messageType: MessageType = .regular,
        channelId: String?,
        messageId: String?,
        text: String?,
        command: String? = nil,
        user: [String: Any]?,
        createdAt: String?,
        updatedAt: String?,
        parentId: String? = nil,
        showReplyInChannel: Bool? = nil,
        quotedMessageId: String? = nil,
        quotedMessage: [String: Any]? = nil,
        attachments: Any? = nil
    ) -> [String: Any]? {
        var mockedMessage = message
        mockedMessage?[messageKey.type.rawValue] = messageType.rawValue
        if let createdAt = createdAt, let updatedAt = updatedAt {
            mockedMessage?[messageKey.createdAt.rawValue] = createdAt
            mockedMessage?[messageKey.updatedAt.rawValue] = updatedAt
        }
        if let messageId = messageId {
            mockedMessage?[messageKey.id.rawValue] = messageId
        }
        if let attachments = attachments {
            mockedMessage?[MessagePayloadsCodingKeys.attachments.rawValue] = attachments as? [[String: Any]]
        }
        if let text = text {
            mockedMessage?[messageKey.text.rawValue] = text
            mockedMessage?[messageKey.html.rawValue] = text.html
            
            if [Links.youtube, Links.unsplash].contains(where: {text.contains($0)}) {
                let jsonWithLink = text.contains(Links.youtube) ? MockFile.youtube : MockFile.unsplash
                let json = TestData.toJson(jsonWithLink)[JSONKey.message] as? [String: Any]
                let linkAttachments =  json?[MessagePayloadsCodingKeys.attachments.rawValue]
                var updatedAttachments = attachments as? [[String: Any]] ?? []
                updatedAttachments += linkAttachments as? [[String: Any]] ?? []
                mockedMessage?[MessagePayloadsCodingKeys.attachments.rawValue] = updatedAttachments
            }
        }
        if let command = command {
            mockedMessage?[messageKey.command.rawValue] = command
        }
        if let channelId = channelId {
            let channelType = ChannelType.messaging.rawValue
            mockedMessage?[messageKey.cid.rawValue] = "\(channelType):\(channelId)"
            mockedMessage?[EventPayload.CodingKeys.channelId.rawValue] = channelId
        }
        if let parentId = parentId {
            mockedMessage?[messageKey.parentId.rawValue] = parentId
        }
        if let showReplyInChannel = showReplyInChannel {
            mockedMessage?[messageKey.showReplyInChannel.rawValue] = showReplyInChannel
        }
        if let quotedMessageId = quotedMessageId {
            mockedMessage?[messageKey.quotedMessageId.rawValue] = quotedMessageId
        }
        if let quotedMessage = quotedMessage {
            mockedMessage?[messageKey.quotedMessage.rawValue] = quotedMessage
        }
        if let user = user {
            mockedMessage?[messageKey.user.rawValue] = user
        }
        return mockedMessage
    }
    
    private func messageUpdate(_ request: HttpRequest) throws -> HttpResponse {
        let messageId = try XCTUnwrap(request.params[EndpointQuery.messageId])
        let message = findMessageById(messageId)
        let cid = message?[messageKey.cid.rawValue] as? String
        let channelId = cid?.split(separator: ":").last.map { String($0) }
        switch request.method {
        case EndpointMethod.delete.rawValue:
            return messageDeletion(
                messageId: messageId,
                channelId: channelId
            )
        case EndpointMethod.get.rawValue:
            return messageInfo(messageId: messageId)
        default:
            return messageCreation(
                request,
                channelId: channelId,
                eventType: .messageUpdated
            )
        }
    }
    
    private func ephemeralMessageCreation(
        messageId: String,
        channelId: String,
        formData: [String: Any]
    ) -> HttpResponse {
        var json = TestData.toJson(.ephemeralMessage)
        var message = findMessageById(messageId)
        let attachmentAction = formData[JSONKey.attachmentAction] as? String
        let timestamp = TestData.currentDate
        
        switch attachmentAction {
        case JSONKey.AttachmentAction.send:
            sendWebsocketMessages(
                httpMessage: message,
                messageText: "",
                messageTimestamp: timestamp,
                messageType: .ephemeral,
                eventType: .messageNew
            )
        case JSONKey.AttachmentAction.shuffle:
            break
        default:
            return .badRequest(nil)
        }
        
        message?[messageKey.updatedAt.rawValue] = timestamp
        json[JSONKey.message] = message
        return .ok(.json(json))
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

        let messageText = message?[messageKey.text.rawValue] as? String ?? ""
        let messageTextComponents = Set(messageText.components(separatedBy: " "))
        
        let messageType: MessageType = messageText.starts(with: "/giphy") ? .ephemeral : .regular
        if messageType == .regular && messageText.starts(with: "/") {
            return messageInvalidCommand(message,
                                         command: String(messageText.dropFirst(1)),
                                         channelId: channelId)
        } else if messageType == .regular && !forbiddenWords.isDisjoint(with: messageTextComponents) {
            return errorMessageHttpResponse(
                from: message,
                errorText: Message.blockedByModerationPolicies,
                channelId: channelId
            )
        }
        
        if let parentId = parentId, let quotedMessageId = quotedMessageId {
            return quotedMessageCreationInThread(
                message,
                messageType: messageType,
                channelId: channelId,
                parentId: parentId,
                quotedMessageId: quotedMessageId,
                eventType: eventType
            )
        } else if let parentId = parentId {
            return messageCreationInThread(
                message,
                messageType: messageType,
                channelId: channelId,
                parentId: parentId,
                eventType: eventType
            )
        } else if let quotedMessageId = quotedMessageId {
            return quotedMessageCreationInChannel(
                message,
                messageType: messageType,
                channelId: channelId,
                quotedMessageId: quotedMessageId,
                eventType: eventType
            )
        } else {
            return messageCreationInChannel(
                message,
                messageType: messageType,
                channelId: channelId,
                eventType: eventType
            )
        }
    }
    
    private func messageCreationInChannel(
        _ message: [String: Any]?,
        messageType: MessageType,
        channelId: String?,
        eventType: EventType = .messageNew
    ) -> HttpResponse {
        let text = message?[messageKey.text.rawValue] as? String ?? ""
        let messageId = message?[messageKey.id.rawValue] as? String
        let mockFile = messageType == .regular ? MockFile.message : MockFile.ephemeralMessage
        var responseJson = TestData.toJson(mockFile)
        let responseMessage = responseJson[JSONKey.message] as? [String: Any]
        let timestamp: String = TestData.currentDate
        let user = setUpUser(source: responseMessage, details: UserDetails.lukeSkywalker)
        let attachments = message?[MessagePayloadsCodingKeys.attachments.rawValue]
            ?? responseMessage?[MessagePayloadsCodingKeys.attachments.rawValue]
        
        let mockedMessage = mockMessage(
            responseMessage,
            messageType: messageType,
            channelId: channelId,
            messageId: messageId,
            text: text,
            user: user,
            createdAt: timestamp,
            updatedAt: timestamp,
            attachments: attachments
        )
        
        if messageType == .ephemeral {
            saveMessage(mockedMessage)
        } else {
            sendWebsocketMessages(
                httpMessage: mockedMessage,
                messageText: text,
                messageTimestamp: timestamp,
                messageType: messageType,
                eventType: eventType
            )
        }
        
        responseJson[JSONKey.message] = mockedMessage
        trackMessage(text, messageType: messageType, eventType: eventType)
        return .ok(.json(responseJson))
    }
    
    private func quotedMessageCreationInChannel(
        _ message: [String: Any]?,
        messageType: MessageType,
        channelId: String?,
        quotedMessageId: String,
        eventType: EventType = .messageNew
    ) -> HttpResponse {
        let text = message?[messageKey.text.rawValue] as? String ?? ""
        let messageId = message?[messageKey.id.rawValue] as? String
        let mockFile = messageType == .regular ? MockFile.message : MockFile.ephemeralMessage
        var responseJson = TestData.toJson(mockFile)
        let responseMessage = responseJson[JSONKey.message] as? [String: Any]
        let timestamp: String = TestData.currentDate
        let user = setUpUser(source: responseMessage, details: UserDetails.lukeSkywalker)
        let quotedMessage = findMessageById(quotedMessageId)
        let attachments = message?[MessagePayloadsCodingKeys.attachments.rawValue]
            ?? responseMessage?[MessagePayloadsCodingKeys.attachments.rawValue]
        
        let mockedMessage = mockMessage(
            responseMessage,
            messageType: messageType,
            channelId: channelId,
            messageId: messageId,
            text: text,
            user: user,
            createdAt: timestamp,
            updatedAt: timestamp,
            quotedMessageId: quotedMessageId,
            quotedMessage: quotedMessage,
            attachments: attachments
        )
        
        if messageType == .ephemeral {
            saveMessage(mockedMessage)
        } else {
            sendWebsocketMessages(
                httpMessage: mockedMessage,
                messageText: text,
                messageTimestamp: timestamp,
                messageType: messageType,
                eventType: eventType
            )
        }
        
        responseJson[JSONKey.message] = mockedMessage
        trackMessage(text, messageType: messageType, eventType: eventType)
        return .ok(.json(responseJson))
    }

    private func messageCreationInThread(
        _ message: [String: Any]?,
        messageType: MessageType,
        channelId: String?,
        parentId: String,
        eventType: EventType = .messageNew
    ) -> HttpResponse {
        let showReplyInChannel = message?[messageKey.showReplyInChannel.rawValue] as? Bool
        let text = message?[messageKey.text.rawValue] as? String ?? ""
        let messageId = message?[messageKey.id.rawValue] as? String
        let mockFile = messageType == .regular ? MockFile.message : MockFile.ephemeralMessage
        var responseJson = TestData.toJson(mockFile)
        let responseMessage = responseJson[JSONKey.message] as? [String: Any]
        let timestamp: String = TestData.currentDate
        let user = setUpUser(source: responseMessage, details: UserDetails.lukeSkywalker)
        let attachments = message?[MessagePayloadsCodingKeys.attachments.rawValue]
            ?? responseMessage?[MessagePayloadsCodingKeys.attachments.rawValue]
        
        let mockedMessage = mockMessage(
            responseMessage,
            messageType: messageType,
            channelId: channelId,
            messageId: messageId,
            text: text,
            user: user,
            createdAt: timestamp,
            updatedAt: timestamp,
            parentId: parentId,
            showReplyInChannel: showReplyInChannel,
            attachments: attachments
        )
        
        if messageType == .ephemeral {
            saveMessage(mockedMessage)
        } else {
            sendWebsocketMessages(
                httpMessage: mockedMessage,
                messageText: text,
                messageTimestamp: timestamp,
                messageType: messageType,
                eventType: eventType
            )
        }
        
        responseJson[JSONKey.message] = mockedMessage
        trackMessage(text, messageType: messageType, eventType: eventType)
        return .ok(.json(responseJson))
    }
    
    private func quotedMessageCreationInThread(
        _ message: [String: Any]?,
        messageType: MessageType,
        channelId: String?,
        parentId: String,
        quotedMessageId: String,
        eventType: EventType = .messageNew
    ) -> HttpResponse {
        let showReplyInChannel = message?[messageKey.showReplyInChannel.rawValue] as? Bool
        let text = message?[messageKey.text.rawValue] as? String ?? ""
        let messageId = message?[messageKey.id.rawValue] as? String
        let mockFile = messageType == .regular ? MockFile.message : MockFile.ephemeralMessage
        var responseJson = TestData.toJson(mockFile)
        let responseMessage = responseJson[JSONKey.message] as? [String: Any]
        let timestamp: String = TestData.currentDate
        let user = setUpUser(source: responseMessage, details: UserDetails.lukeSkywalker)
        let quotedMessage = findMessageById(quotedMessageId)
        let attachments = message?[MessagePayloadsCodingKeys.attachments.rawValue]
            ?? responseMessage?[MessagePayloadsCodingKeys.attachments.rawValue]
        
        
        let mockedMessage = mockMessage(
            responseMessage,
            messageType: messageType,
            channelId: channelId,
            messageId: messageId,
            text: text,
            user: user,
            createdAt: timestamp,
            updatedAt: timestamp,
            parentId: parentId,
            showReplyInChannel: showReplyInChannel,
            quotedMessageId: quotedMessageId,
            quotedMessage: quotedMessage,
            attachments: attachments
        )
        
        if messageType == .ephemeral {
            saveMessage(mockedMessage)
        } else {
            sendWebsocketMessages(
                httpMessage: mockedMessage,
                messageText: text,
                messageTimestamp: timestamp,
                messageType: messageType,
                eventType: eventType
            )
        }
        
        responseJson[JSONKey.message] = mockedMessage
        trackMessage(text, messageType: messageType, eventType: eventType)
        return .ok(.json(responseJson))
    }
    
    private func sendWebsocketMessages(
        httpMessage: [String: Any]?,
        messageText: String,
        messageTimestamp: String,
        messageType: MessageType,
        eventType: EventType
    ){
        if let parentId = httpMessage?[messageKey.parentId.rawValue] as? String {
            let parentMessage = findMessageById(parentId)
            websocketMessage(
                parentMessage?[messageKey.text.rawValue] as? String,
                channelId: httpMessage?[EventPayload.CodingKeys.channelId.rawValue] as? String,
                messageId: parentId,
                timestamp: parentMessage?[messageKey.createdAt.rawValue] as? String,
                eventType: .messageUpdated,
                user: parentMessage?[JSONKey.user] as? [String: Any]
            ) { message in
                message?[messageKey.threadParticipants.rawValue] = [httpMessage?[messageKey.user.rawValue]]
                return message
            }
        }
        
        websocketMessage(
            messageText,
            channelId: httpMessage?[EventPayload.CodingKeys.channelId.rawValue] as? String,
            messageId: httpMessage?[messageKey.id.rawValue] as? String,
            timestamp: messageTimestamp,
            messageType: messageType,
            eventType: eventType,
            user: httpMessage?[messageKey.user.rawValue] as? [String: Any]
        ) { message in
            if let parentId = httpMessage?[messageKey.parentId.rawValue] as? String {
                message?[messageKey.parentId.rawValue] = parentId
            }
            if let showReplyInChannel = httpMessage?[messageKey.showReplyInChannel.rawValue] {
                message?[messageKey.showReplyInChannel.rawValue] = showReplyInChannel
            }
            if let attachments = httpMessage?[messageKey.attachments.rawValue] as? [[String: Any]] {
                message?[MessagePayloadsCodingKeys.attachments.rawValue] = attachments
            }
            if let quotedMessageId = httpMessage?[messageKey.quotedMessageId.rawValue] as? String {
                let quotedMessage = self.findMessageById(quotedMessageId)
                message?[messageKey.quotedMessageId.rawValue] = quotedMessageId
                message?[messageKey.quotedMessage.rawValue] = quotedMessage
            }
            return message
        }
    }
    
    private func messageDeletion(messageId: String, channelId: String?) -> HttpResponse {
        var json = TestData.toJson(.message)
        let message = findMessageById(messageId)
        let timestamp: String = TestData.currentDate
        let user = message?[JSONKey.user] as? [String: Any]
        let mockedMessage = mockDeletedMessage(message, user: user)
        
        websocketMessage(
            channelId: channelId,
            messageId: messageId,
            timestamp: timestamp,
            eventType: .messageDeleted,
            user: user
        )
        
        json[JSONKey.message] = mockedMessage
        return .ok(.json(json))
    }
    
    private func messageInfo(messageId: String) -> HttpResponse {
        var json = TestData.toJson(.message)
        json[JSONKey.message] = findMessageById(messageId)
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
        var responseJson = TestData.toJson(.message)
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
            messageType: .error,
            channelId: channelId,
            messageId: messageId,
            text: text,
            command: command,
            user: user,
            createdAt: timestamp,
            updatedAt: timestamp
        )

        responseJson[JSONKey.message] = mockedMessage
        return .ok(.json(responseJson))
    }
    
    private func errorMessageHttpResponse(
        from message: [String: Any]?,
        errorText: String,
        channelId: String?
    ) -> HttpResponse {
        let messageId = message?[messageKey.id.rawValue] as? String
        var responseJson = TestData.toJson(.message)
        let responseMessage = responseJson[JSONKey.message] as? [String: Any]
        let timestamp: String = TestData.currentDate
        let user = setUpUser(source: responseMessage, details: UserDetails.lukeSkywalker)
        
        let mockedMessage = mockMessage(
            responseMessage,
            messageType: .error,
            channelId: channelId,
            messageId: messageId,
            text: errorText,
            user: user,
            createdAt: timestamp,
            updatedAt: timestamp
        )

        responseJson[JSONKey.message] = mockedMessage
        return .ok(.json(responseJson))
    }
}
