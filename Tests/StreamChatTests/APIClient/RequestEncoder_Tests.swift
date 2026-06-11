//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class RequestEncoder_Tests: XCTestCase {
    private var encoder: DefaultRequestEncoder!

    override func setUp() {
        super.setUp()
        encoder = DefaultRequestEncoder(
            baseURL: URL(string: "https://chat.stream-io-api.com")!,
            apiKey: APIKey("test-key")
        )
    }

    override func tearDown() {
        encoder = nil
        super.tearDown()
    }

    func test_encodeGetRequest_addsPathMethodAndQueryItems() throws {
        let endpoint: Endpoint<GetMessageResponse> = .getMessage(id: "message-id")
        let request = try encoder.encodeRequest(for: endpoint.withoutToken)
        let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false))

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(components.path, "/api/v2/chat/messages/message-id")
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "api_key" })?.value, "test-key")
        XCTAssertNil(request.httpBody)
    }

    func test_encodePostRequest_encodesBody() throws {
        let body = SendEventRequest(event: EventRequest(type: "custom"))
        let endpoint: Endpoint<EventResponse> = .sendEvent(type: "messaging", id: "general", sendEventRequest: body)

        let request = try encoder.encodeRequest(for: endpoint.withoutToken)
        let bodyData = try XCTUnwrap(request.httpBody)
        let bodyObject = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any]

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/api/v2/chat/channels/messaging/general/event")
        XCTAssertEqual((bodyObject?["event"] as? [String: Any])?["type"] as? String, "custom")
    }

    func test_encodeWriteRequest_whenBodyIsNil_encodesEmptyJSONObjectBody() throws {
        for method in [EndpointMethod.post, .patch, .put] {
            let endpoint = Endpoint<EmptyResponse>(
                path: .custom("custom/path"),
                method: method,
                requiresConnectionId: false,
                requiresToken: false,
                body: nil
            )

            let request = try encoder.encodeRequest(for: endpoint)

            XCTAssertEqual(request.httpMethod, method.rawValue)
            XCTAssertEqual(request.httpBody, Data("{}".utf8))
        }
    }

    func test_encodeDeleteRequest_encodesGeneratedQueryItems() throws {
        let endpoint: Endpoint<DeleteMessageResponse> = .deleteMessage(
            id: "message-id",
            hard: true,
            deletedBy: "moderator",
            deleteForMe: false
        )

        let request = try encoder.encodeRequest(for: endpoint.withoutToken)
        let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false))

        XCTAssertEqual(request.httpMethod, "DELETE")
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "hard" })?.value, "true")
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "deleted_by" })?.value, "moderator")
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "delete_for_me" })?.value, "false")
    }

    func test_encodeDeleteRequest_omitsNilQueryItems() throws {
        let endpoint: Endpoint<DeleteMessageResponse> = .deleteMessage(
            id: "message-id",
            hard: true,
            deletedBy: nil,
            deleteForMe: nil
        )

        let request = try encoder.encodeRequest(for: endpoint.withoutToken)
        let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "hard" })?.value, "true")
        XCTAssertNil(components.queryItems?.first(where: { $0.name == "deleted_by" }))
        XCTAssertNil(components.queryItems?.first(where: { $0.name == "delete_for_me" }))
    }

    func test_encodePostRequest_omitsNilQueryItems() throws {
        let endpoint: Endpoint<SyncResponse> = .sync(
            syncRequest: SyncRequest(channelCids: ["messaging:general"], lastSyncAt: Date(timeIntervalSince1970: 1_700_000_000)),
            withInaccessibleCids: nil,
            watch: nil
        )

        let request = try encoder.encodeRequest(for: endpoint.withoutToken)
        let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.queryItems?.map(\.name), ["api_key"])
    }
}

private extension Endpoint {
    var withoutToken: Endpoint<ResponseType> {
        Endpoint<ResponseType>(
            path: path,
            method: method,
            queryItems: queryItems,
            requiresConnectionId: false,
            requiresToken: false,
            body: body
        )
    }
}
