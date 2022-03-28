//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

extension StreamMockServer {
    
    func configureMessagingEndpoints() {
        server[MockEndpoint.message] = { request in
            self.messageCreation(request: request)
        }
        server[MockEndpoint.messageUpdate] = { request in
            self.messageUpdate(request: request)
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
        updatedAt: String?
    ) -> [String: Any] {
        var mockedMessage = message
        mockedMessage[MessagePayloadsCodingKeys.id.rawValue] = messageId
        mockedMessage[MessagePayloadsCodingKeys.createdAt.rawValue] = createdAt
        mockedMessage[MessagePayloadsCodingKeys.updatedAt.rawValue] = updatedAt
        mockedMessage[MessagePayloadsCodingKeys.text.rawValue] = text
        mockedMessage[MessagePayloadsCodingKeys.html.rawValue] = text?.html
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
        let requestMessage = requestJson[TopLevelKey.message] as! [String: Any]
        let text = requestMessage[MessagePayloadsCodingKeys.text.rawValue] as! String
        let messageId = requestMessage[MessagePayloadsCodingKeys.id.rawValue] as! String
        var responseJson = TestData.toJson(.httpMessage)
        let responseMessage = responseJson[TopLevelKey.message] as! [String: Any]
        let timestamp: String = TestData.currentDate
        let user = setUpUser(
            responseMessage[MessagePayloadsCodingKeys.user.rawValue] as! [String: Any],
            userDetails: UserDetails.lukeSkywalker
        )
        
        websocketMessage(
            text,
            messageId: messageId,
            timestamp: timestamp,
            eventType: .messageNew,
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
    
    private func messageDeletion(request: HttpRequest) -> HttpResponse {
        let messageId = try! XCTUnwrap(request.params[":message_id"])
        var json = TestData.toJson(.httpMessage)
        let messageDetails = findMessageById(messageId)
        let timestamp: String = TestData.currentDate
        let user = setUpUser(
            messageDetails[MessagePayloadsCodingKeys.user.rawValue] as! [String: Any],
            userDetails: UserDetails.lukeSkywalker
        )
        var mockedMessage = mockDeletedMessage(messageDetails)
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
}
