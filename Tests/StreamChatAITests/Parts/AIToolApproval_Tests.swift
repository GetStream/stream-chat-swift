//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class AIToolApproval_Tests: XCTestCase {
    private func call(_ json: String) throws -> AIToolCallPart {
        try XCTUnwrap(AIMessagePart(type: "ai_tool_call", payload: Data(json.utf8))?.toolCall)
    }

    func testACallThatAsksFirstCarriesItsQuestion() throws {
        let waiting = try call(#"{"id":"toolu_01A","name":"athena_device_location","status":"awaiting_approval","executor":"client","target_user_id":"u_1","target_client_id":"ios-1","approval":{"title":"Share your location?","message":"Only your city is shared.","reason":"to check the local weather","allow_title":"Share location","decline_title":"Don't share"}}"#)
        XCTAssertEqual(waiting.status, .awaitingApproval)
        XCTAssertEqual(waiting.approval, AIToolApproval(
            title: "Share your location?",
            message: "Only your city is shared.",
            reason: "to check the local weather",
            allowTitle: "Share location",
            declineTitle: "Don't share"
        ))
        XCTAssertTrue(waiting.isAwaitingApproval(userID: "u_1", clientID: "ios-1"))
        XCTAssertFalse(waiting.isAwaitingApproval(userID: "u_1", clientID: "ios-2"), "a client tool is answered on its install")
        XCTAssertFalse(waiting.isAwaitingApproval(userID: "u_2", clientID: "ios-1"))
        XCTAssertFalse(waiting.isAwaiting(userID: "u_1", clientID: "ios-1"), "the device doesn't run it yet")
        XCTAssertFalse(waiting.status.isFinished)
        XCTAssertEqual(AIToolApprovalCard.lines(of: try XCTUnwrap(waiting.approval)), ["To check the local weather.", "Only your city is shared."])
    }

    func testAServerToolsQuestionIsAnsweredFromAnyOfThePersonsDevices() throws {
        let waiting = try call(#"{"id":"call-1","name":"send_email","status":"awaiting_approval","target_user_id":"u_1","approval":{"title":"Send this email?"}}"#)
        XCTAssertTrue(waiting.isAwaitingApproval(userID: "u_1", clientID: "web-1"))
        XCTAssertEqual(waiting.approval?.allowTitle, "Allow")
        XCTAssertEqual(waiting.approval?.declineTitle, "Don't Allow")
        XCTAssertEqual(AIToolApprovalCard.lines(of: try XCTUnwrap(waiting.approval)), [])
    }

    func testAnsweredQuestionsSayHowAndADeclinedCallIsOver() throws {
        let allowed = try call(#"{"id":"toolu_01A","status":"awaiting_client","executor":"client","target_user_id":"u_1","target_client_id":"ios-1","approval":{"title":"Share your location?","decision":"allowed"}}"#)
        XCTAssertEqual(allowed.approval?.decision, .allowed)
        XCTAssertFalse(allowed.isDeclined)
        XCTAssertTrue(allowed.isAwaiting(userID: "u_1", clientID: "ios-1"), "allowed, the device runs it")
        XCTAssertFalse(allowed.isAwaitingApproval(userID: "u_1", clientID: "ios-1"))

        let declined = try call(#"{"id":"toolu_01B","status":"cancelled","summary":"Location not shared","approval":{"title":"Share your location?","decision":"declined"}}"#)
        XCTAssertTrue(declined.isDeclined)
        XCTAssertTrue(declined.status.isFinished)
    }

    func testAQuestionWithoutATitleAsksNothing() throws {
        let odd = try call(#"{"id":"toolu_01A","status":"awaiting_approval","target_user_id":"u_1","approval":{"message":"?"}}"#)
        XCTAssertNil(odd.approval)
        XCTAssertFalse(odd.isAwaitingApproval(userID: "u_1", clientID: "ios-1"))
        let notAnObject = try call(#"{"id":"toolu_01A","status":"awaiting_approval","approval":"yes"}"#)
        XCTAssertNil(notAnObject.approval)
    }
}
