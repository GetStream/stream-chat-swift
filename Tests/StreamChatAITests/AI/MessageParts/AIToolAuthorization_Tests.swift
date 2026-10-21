//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class AIToolAuthorization_Tests: XCTestCase {
    private func call(_ json: String) throws -> AIToolCallPart {
        try XCTUnwrap(AIMessagePart(type: "ai_tool_call", payload: Data(json.utf8))?.toolCall)
    }

    func testACallWaitingForASignInCarriesItForItsPerson() throws {
        let waiting = try call(#"{"id":"call-1","name":"linear__list_tools","display_title":"Using Linear","status":"awaiting_authorization","executor":"server","target_user_id":"u_1","authorization":{"type":"oauth","provider":"linear","provider_name":"Linear","title":"Connect Linear","message":"You sign in at Linear.","url":"https://router.example/v1/agents/connectors/oauth/launch/a1","handoff_token":"tok_-1","expires_at":"2026-10-20T12:10:00.123456Z"}}"#)
        XCTAssertEqual(waiting.status, .awaitingAuthorization)
        var read = try XCTUnwrap(waiting.authorization)
        XCTAssertEqual(try XCTUnwrap(read.expiresAt).timeIntervalSince1970, 1_792_498_200.123, accuracy: 0.001)
        read.expiresAt = nil
        XCTAssertEqual(read, AIToolAuthorization(
            provider: "linear",
            providerName: "Linear",
            title: "Connect Linear",
            message: "You sign in at Linear.",
            url: URL(string: "https://router.example/v1/agents/connectors/oauth/launch/a1")!,
            handoffToken: "tok_-1"
        ))
        XCTAssertTrue(waiting.isAwaitingAuthorization(userID: "u_1"))
        XCTAssertFalse(waiting.isAwaitingAuthorization(userID: "u_2"), "only its person signs in")
        XCTAssertFalse(waiting.isAwaitingApproval(userID: "u_1", clientID: "ios-1"))
        XCTAssertFalse(waiting.status.isFinished)
    }

    func testTheSignInPageCarriesTheHandoffTokenInItsFragment() throws {
        let waiting = try call(#"{"id":"call-1","status":"awaiting_authorization","target_user_id":"u_1","authorization":{"title":"Connect Linear","url":"https://router.example/launch/a1","handoff_token":"tok_-1"}}"#)
        let authorization = try XCTUnwrap(waiting.authorization)
        XCTAssertEqual(authorization.launchURL.absoluteString, "https://router.example/launch/a1#handoff_token=tok_-1")
        XCTAssertEqual(authorization.kind, .oauth, "a sign-in that names no type is a consent at the provider")

        var spent = authorization
        spent.handoffToken = nil
        XCTAssertEqual(spent.launchURL, spent.url)
    }

    func testAnEndedSignInSaysHowAndADeclinedOneIsOver() throws {
        let connected = try call(#"{"id":"call-1","status":"running","target_user_id":"u_1","authorization":{"title":"Connect Linear","url":"https://router.example/launch/a1","expires_at":"2026-10-20T12:10:00Z","status":"connected"}}"#)
        XCTAssertEqual(connected.authorization?.status, .connected)
        XCTAssertEqual(connected.authorization?.expiresAt, Date(timeIntervalSince1970: 1_792_498_200), "a time with no fractional seconds")
        XCTAssertNil(connected.authorization?.handoffToken)
        XCTAssertFalse(connected.isAwaitingAuthorization(userID: "u_1"))
        XCTAssertFalse(connected.isDeclined)

        let declined = try call(#"{"id":"call-2","status":"cancelled","summary":"Not connected","authorization":{"title":"Connect Linear","url":"https://router.example/launch/a2","status":"declined"}}"#)
        XCTAssertTrue(declined.isDeclined)
        XCTAssertTrue(declined.status.isFinished)
    }

    func testASignInWithoutATitleOrAPageAsksNothing() throws {
        let untitled = try call(#"{"id":"call-1","status":"awaiting_authorization","target_user_id":"u_1","authorization":{"url":"https://router.example/launch/a1"}}"#)
        XCTAssertNil(untitled.authorization)
        XCTAssertFalse(untitled.isAwaitingAuthorization(userID: "u_1"))
        let nowhere = try call(#"{"id":"call-1","status":"awaiting_authorization","target_user_id":"u_1","authorization":{"title":"Connect Linear"}}"#)
        XCTAssertNil(nowhere.authorization)
    }
}
