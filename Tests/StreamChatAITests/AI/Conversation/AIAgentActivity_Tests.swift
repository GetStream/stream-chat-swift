//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class AIAgentActivity_Tests: XCTestCase {
    func test_states_areThoseOfStreamChatsAIIndicator() {
        XCTAssertEqual(AIAgentActivity.State.thinking.rawValue, "AI_STATE_THINKING")
        XCTAssertEqual(AIAgentActivity.State.checkingExternalSources.rawValue, "AI_STATE_EXTERNAL_SOURCES")
        XCTAssertEqual(AIAgentActivity.State.generating.rawValue, "AI_STATE_GENERATING")
        XCTAssertEqual(AIAgentActivity.State.error.rawValue, "AI_STATE_ERROR")
        XCTAssertEqual(AIAgentActivity.State.thinking.description, "AI_STATE_THINKING")
    }

    func test_activity_fromAnIndicatorsRawState() {
        XCTAssertEqual(
            AIAgentActivity(state: .init(rawValue: "AI_STATE_EXTERNAL_SOURCES"), text: "Searching the web"),
            AIAgentActivity(state: .checkingExternalSources, text: "Searching the web")
        )
        XCTAssertNil(AIAgentActivity(state: .thinking).text)
    }
}
