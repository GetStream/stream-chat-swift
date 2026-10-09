//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class AIMessagePart_Tests: XCTestCase {
    private func payload(_ json: String) -> Data { Data(json.utf8) }

    func testStepsDecodeInOrderAndOtherAttachmentsAreSkipped() throws {
        let parts = AIMessagePart.parts(from: [
            ("ai_reasoning", payload(#"{"type":"ai_reasoning","v":1,"id":"r1","status":"completed","summary":"Needs the user's location first","duration_ms":3200}"#)),
            ("athena_image", payload(#"{"artifact_id":"a1"}"#)),
            ("ai_tool_call", payload(#"{"type":"ai_tool_call","v":1,"id":"toolu_01A","name":"get_location","display_title":"Checking your location","status":"awaiting_client","executor":"client","target_user_id":"u_123","target_client_id":"ios-7F3A","arguments":{"accuracy":"city"}}"#)),
            ("ai_reasoning", payload(#"{"id":"r2","status":"streaming","preview":"Now that I know the city…"}"#))
        ])

        XCTAssertEqual(parts.map(\.id), ["r1", "toolu_01A", "r2"])
        XCTAssertEqual(parts.map(\.kind), [.reasoning, .toolCall, .reasoning])
        let first = try XCTUnwrap(parts[0].reasoning)
        let call = try XCTUnwrap(parts[1].toolCall)
        let live = try XCTUnwrap(parts[2].reasoning)
        XCTAssertNil(parts[0].toolCall)
        XCTAssertEqual(first.status, .completed)
        XCTAssertEqual(first.summary, "Needs the user's location first")
        XCTAssertEqual(first.duration, 3.2)
        XCTAssertEqual(call.status, .awaitingClient)
        XCTAssertEqual(call.executor, .client)
        XCTAssertEqual(call.displayTitle, "Checking your location")
        XCTAssertTrue(call.isAwaiting(userID: "u_123", clientID: "ios-7F3A"))
        XCTAssertFalse(call.isAwaiting(userID: "u_123", clientID: "ios-OTHER"))
        XCTAssertFalse(call.isAwaiting(userID: "u_456", clientID: "ios-7F3A"))
        struct Arguments: Decodable { let accuracy: String }
        XCTAssertEqual(try call.decodeArguments(as: Arguments.self).accuracy, "city")
        XCTAssertTrue(live.isStreaming)
        XCTAssertEqual(live.preview, "Now that I know the city…")
    }

    func testNewKindsAndStatusesNeverBreakDecoding() throws {
        let parts = AIMessagePart.parts(from: [
            ("ai_tool_call", payload(#"{"id":"c1","name":"search","status":"paused_for_review","duration_ms":"fast"}"#)),
            ("ai_reasoning", payload("not json")),
            ("ai_tool_call", payload(#"{"id":"c2","v":2,"name":"future"}"#)),
            ("ai_citation", payload(#"{"id":"s1","url":"https://getstream.io","title":"Stream"}"#))
        ])

        let call = try XCTUnwrap(parts[0].toolCall)
        XCTAssertEqual(call.status.rawValue, "paused_for_review", "an unknown status keeps its value")
        XCTAssertFalse(call.status.isFinished)
        XCTAssertEqual(call.executor, .server)
        XCTAssertNil(call.durationMS, "a field of the wrong type reads as missing")

        let broken = try XCTUnwrap(parts[1].reasoning)
        XCTAssertEqual(broken.id, "ai_reasoning-1", "a step without an ID is known by its position")
        XCTAssertEqual(broken.status, .completed)

        XCTAssertEqual(parts[2].kind, .toolCall)
        XCTAssertEqual(parts[2].version, 2)
        XCTAssertNil(parts[2].toolCall, "a newer format of a known kind has no typed view")
        XCTAssertFalse(parts[2].isSupported)

        XCTAssertEqual(parts[3].kind, "ai_citation")
        XCTAssertFalse(parts[3].isSupported)
        struct Citation: Decodable { let url: String; let title: String }
        XCTAssertEqual(try parts[3].decode(Citation.self).title, "Stream", "a kind of your own reads from its payload")
    }

    func testAReasoningStepShowsItsLiveTextOrItsPreview() {
        let step = AIReasoningPart(id: "r1", status: .completed, summary: "Weighing it", preview: "Weighing it up", durationMS: 12400)

        XCTAssertEqual(StreamingReasoningView(part: step).text, "Weighing it up")
        XCTAssertEqual(StreamingReasoningView(part: step, text: "Weighing it up, then more").text, "Weighing it up, then more")
        XCTAssertEqual(StreamingReasoningView(part: step).summary, "Weighing it")
        XCTAssertFalse(StreamingReasoningView(part: step).isThinking)
    }
}
