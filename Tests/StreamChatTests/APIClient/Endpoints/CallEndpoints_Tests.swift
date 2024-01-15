//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class CallEndpoints_Tests: XCTestCase {
    func test_getCallToken_buildsCorrectly() {
        let callId: String = .unique

        // GIVEN
        let expectedEndpoint = Endpoint<CallTokenPayload>(
            path: .callToken(callId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true
        )

        // WHEN
        let endpoint: Endpoint<CallTokenPayload> = .getCallToken(callId: callId)

        // THEN
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("calls/\(callId)", endpoint.path.value)
    }

    func test_createCall_buildsCorrectly() {
        let channedId: ChannelId = .unique
        let callId: String = .unique
        let callType = "video"

        // GIVEN
        let expectedEndpoint: Endpoint<CreateCallPayload> = Endpoint<CreateCallPayload>(
            path: .createCall(channedId.apiPath),
            method: .post,
            body: CallRequestBody(id: callId, type: callType)
        )

        // WHEN
        let endpoint: Endpoint<CreateCallPayload> = .createCall(cid: channedId, callId: callId, type: callType)

        // THEN
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(channedId.apiPath)/call", endpoint.path.value)
    }
}
