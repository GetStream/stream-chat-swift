//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageEndpoints_Tests: XCTestCase {
    func test_getMessage_buildsCorrectly() {
        let messageId: MessageId = .unique

        let expectedEndpoint = Endpoint<MessagePayload.Boxed>(
            path: .message(messageId),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )

        // Build endpoint
        let endpoint: Endpoint<MessagePayload.Boxed> = .getMessage(messageId: messageId)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)", endpoint.path.value)
    }

    func test_deleteMessage_whenHardDeleteDisabled_buildsCorrectly() {
        let messageId: MessageId = .unique

        let expectedEndpoint = Endpoint<MessagePayload.Boxed>(
            path: .message(messageId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "hard": false
            ]
        )

        // Build endpoint
        let endpoint: Endpoint<MessagePayload.Boxed> = .deleteMessage(messageId: messageId, hard: false)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)", endpoint.path.value)
    }

    func test_deleteMessage_whenHardDeleteEnabled_buildsCorrectly() {
        let messageId: MessageId = .unique

        let expectedEndpoint = Endpoint<MessagePayload.Boxed>(
            path: .message(messageId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "hard": true
            ]
        )

        // Build endpoint
        let endpoint: Endpoint<MessagePayload.Boxed> = .deleteMessage(messageId: messageId, hard: true)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)", endpoint.path.value)
    }

    func test_deleteMessage_whenDeleteForMeEnabled_buildsCorrectly() {
        let messageId: MessageId = .unique

        let expectedEndpoint = Endpoint<MessagePayload.Boxed>(
            path: .message(messageId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "hard": false,
                "delete_for_me": true
            ]
        )

        // Build endpoint
        let endpoint: Endpoint<MessagePayload.Boxed> = .deleteMessage(messageId: messageId, hard: false, deleteForMe: true)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)", endpoint.path.value)
    }

    func test_deleteMessage_whenDeleteForMeDisabled_buildsCorrectly() {
        let messageId: MessageId = .unique

        let expectedEndpoint = Endpoint<MessagePayload.Boxed>(
            path: .message(messageId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "hard": false,
                "delete_for_me": false
            ]
        )

        // Build endpoint
        let endpoint: Endpoint<MessagePayload.Boxed> = .deleteMessage(messageId: messageId, hard: false, deleteForMe: false)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)", endpoint.path.value)
    }

    func test_deleteMessage_whenDeleteForMeIsNil_buildsCorrectly() {
        let messageId: MessageId = .unique

        let expectedEndpoint = Endpoint<MessagePayload.Boxed>(
            path: .message(messageId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "hard": false
            ]
        )

        // Build endpoint
        let endpoint: Endpoint<MessagePayload.Boxed> = .deleteMessage(messageId: messageId, hard: false, deleteForMe: nil)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)", endpoint.path.value)
    }

    func test_editMessage_buildsCorrectly() {
        let payload = MessageRequestBody(
            id: .unique,
            user: .init(id: .unique, name: .unique, imageURL: .unique(), extraData: .init()),
            text: .unique,
            type: nil,
            extraData: [:]
        )

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .message(payload.id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "message": AnyEncodable(payload),
                "skip_enrich_url": AnyEncodable(true),
                "skip_push": AnyEncodable(false)
            ]
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .editMessage(
            payload: payload,
            skipEnrichUrl: true,
            skipPush: false
        )

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(payload.id)", endpoint.path.value)
    }

    func test_editMessage_withSkipPush_buildsCorrectly() {
        let payload = MessageRequestBody(
            id: .unique,
            user: .init(id: .unique, name: .unique, imageURL: .unique(), extraData: .init()),
            text: .unique,
            type: nil,
            extraData: [:]
        )

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .message(payload.id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "message": AnyEncodable(payload),
                "skip_enrich_url": AnyEncodable(true),
                "skip_push": AnyEncodable(true)
            ]
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .editMessage(payload: payload, skipEnrichUrl: true, skipPush: true)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(payload.id)", endpoint.path.value)
    }
    
    func test_pinMessage_buildsCorrectly() {
        let messageId: MessageId = .unique
        let payload: MessagePartialUpdateRequest = .init(set: .init(pinned: true))

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .pinMessage(messageId),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: payload
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .pinMessage(messageId: messageId, request: payload)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)", endpoint.path.value)
    }

    func test_loadReplies_buildsCorrectly() {
        let messageId: MessageId = .unique
        let pagination: MessagesPagination = .init(pageSize: 10)

        let expectedEndpoint = Endpoint<MessageRepliesPayload>(
            path: .replies(messageId),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: pagination
        )

        // Build endpoint
        let endpoint: Endpoint<MessageRepliesPayload> = .loadReplies(messageId: messageId, pagination: pagination)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)/replies", endpoint.path.value)
    }

    func test_sendMessageAction_buildsCorrectly() {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let action = AttachmentAction(
            name: .unique,
            value: .unique,
            style: .primary,
            type: .button,
            text: .unique
        )

        let expectedEndpoint = Endpoint<MessagePayload.Boxed>(
            path: .messageAction(messageId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: AttachmentActionRequestBody(
                cid: cid,
                messageId: messageId,
                action: action
            )
        )

        // Build endpoint.
        let endpoint: Endpoint<MessagePayload.Boxed> = .dispatchEphemeralMessageAction(
            cid: cid,
            messageId: messageId,
            action: action
        )

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)/action", endpoint.path.value)
    }

    func test_translate_buildsCorrectly() {
        let messageId: MessageId = .unique
        let language = TranslationLanguage.allCases.randomElement()!

        let expectedEndpoint = Endpoint<MessagePayload.Boxed>(
            path: .translateMessage(messageId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["language": language.languageCode]
        )

        let endpoint: Endpoint<MessagePayload.Boxed> = .translate(messageId: messageId, to: language)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)/translate", endpoint.path.value)
    }

    func test_partialUpdateMessage_buildsCorrectly() {
        let messageId: MessageId = .unique
        let request = MessagePartialUpdateRequest(
            set: .init(pinned: false, text: .unique),
            unset: ["custom_text"],
            skipEnrichUrl: true
        )

        let expectedEndpoint = Endpoint<MessagePayload.Boxed>(
            path: .editMessage(messageId),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )

        // Build endpoint
        let endpoint: Endpoint<MessagePayload.Boxed> = .partialUpdateMessage(messageId: messageId, request: request)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)", endpoint.path.value)
    }
}
