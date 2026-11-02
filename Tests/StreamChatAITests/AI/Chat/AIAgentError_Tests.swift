//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class AIAgentError_Tests: XCTestCase {
    func test_description_isWhatTheAgentSaid() {
        XCTAssertEqual(AIAgentError(message: "Rate limited").localizedDescription, "Rate limited")
    }

    func test_description_whenTheAgentSaidNothing() {
        XCTAssertEqual(AIAgentError().localizedDescription, "The agent couldn't answer. Try again.")
        XCTAssertEqual(AIAgentError(message: "").localizedDescription, "The agent couldn't answer. Try again.")
    }
}
