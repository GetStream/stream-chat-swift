//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class MessageEndpoints_Tests: XCTestCase {
    func test_getMessage_buildsCorrectly() {
        let messageId: MessageId = .unique
        
        let expectedEndpoint = Endpoint<MessagePayload<DefaultDataTypes>>(
            path: "messages/\(messageId)",
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
        
        // Build endpoint
        let endpoint: Endpoint<MessagePayload<DefaultDataTypes>> = .getMessage(messageId: messageId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_deleteMessage_buildsCorrectly() {
        let messageId: MessageId = .unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "messages/\(messageId)",
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .deleteMessage(messageId: messageId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_editMessage_buildsCorrectly() {
        let payload = MessageRequestBody<DefaultDataTypes>(
            id: .unique,
            user: .init(id: .unique, extraData: .init()),
            text: .unique,
            extraData: .init()
        )
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "messages/\(payload.id)",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["message": payload]
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .editMessage(payload: payload)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}
