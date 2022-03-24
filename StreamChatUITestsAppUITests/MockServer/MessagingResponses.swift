//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter

extension StreamMockServer {
    
    func configureMessagingEndpoints() {
        server[MockEndpoint.message] = { request in
            self.messageCreation(request: request)
        }
        server[MockEndpoint.messageUpdate] = { request in
            self.messageUpdate(request: request)
        }
    }
    
    func mockMessage(
        _ message: Dictionary<String, Any>,
        messageId: String?,
        text: String?,
        createdAt: String?,
        updatedAt: String?,
        deleted: Bool = false,
        saveDetails: Bool = false
    ) -> Dictionary<String, Any> {
        let codingKeys = MessagePayloadsCodingKeys.self
        var mockedMessage = message
        mockedMessage[codingKeys.id.rawValue] = messageId
        mockedMessage[codingKeys.createdAt.rawValue] = createdAt
        mockedMessage[codingKeys.updatedAt.rawValue] = updatedAt
        mockedMessage[codingKeys.text.rawValue] = text
        mockedMessage[codingKeys.html.rawValue] = text?.html
        if saveDetails {
            saveMessageDetails(
                messageId: messageId!,
                text: text!,
                createdAt: createdAt!,
                updatedAt: updatedAt!
            )
        }
        if deleted {
            mockedMessage[codingKeys.deletedAt.rawValue] = TestData.currentDate
            mockedMessage[codingKeys.type.rawValue] = MessageType.deleted.rawValue
            removeMessageDetails(messageId: messageId!)
        }
        return mockedMessage
    }
    
    private func messageUpdate(request: HttpRequest) -> HttpResponse {
        if request.method == EndpointMethod.delete.rawValue {
            return messageDeletion(request: request)
        } else {
            return messageCreation(request: request)
        }
    }
    
    private func messageCreation(request: HttpRequest) -> HttpResponse {
        let requestJson = TestData.toJson(request.body)
        let messageKey = TopLevelKey.message.rawValue
        let requestMessage = requestJson[messageKey] as! Dictionary<String, Any>
        let text = requestMessage[MessagePayloadsCodingKeys.text.rawValue] as! String
        let messageId = requestMessage[MessagePayloadsCodingKeys.id.rawValue] as! String
        var responseJson = TestData.toJson(.httpMessage)
        let responseMessage = responseJson[messageKey] as! Dictionary<String, Any>
        let timestamp: String = TestData.currentDate
        responseJson[messageKey] = mockMessage(
            responseMessage,
            messageId: messageId,
            text: text,
            createdAt: timestamp,
            updatedAt: timestamp,
            saveDetails: true
        )
        return .ok(.json(responseJson))
    }
    
    private func messageDeletion(request: HttpRequest) -> HttpResponse {
        let messageId = request.params[":message_id"]
        var json = TestData.toJson(.httpMessage)
        let messageKey = TopLevelKey.message.rawValue
        let message = json[messageKey] as! Dictionary<String, Any>
        let messageDetails = getMessageDetails(messageId: messageId!)
        json[messageKey] = mockMessage(
            message,
            messageId: messageId,
            text: messageDetails[.text],
            createdAt: messageDetails[.createdAt],
            updatedAt: TestData.currentDate,
            deleted: true
        )
        return .ok(.json(json))
    }
}
