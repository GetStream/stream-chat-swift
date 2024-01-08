//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageModerationDetails_Tests: XCTestCase {
    func test_action_whenIsBounce() {
        let moderationDetails = MessageModerationDetails(
            originalText: "original",
            action: .init(rawValue: "MESSAGE_RESPONSE_ACTION_BOUNCE")
        )

        XCTAssertEqual(moderationDetails.action, .bounce)
    }

    func test_action_whenIsFlag() {
        let moderationDetails = MessageModerationDetails(
            originalText: "original",
            action: .init(rawValue: "MESSAGE_RESPONSE_ACTION_FLAG")
        )

        XCTAssertEqual(moderationDetails.action, .flag)
    }

    func test_action_whenIsBlock() {
        let moderationDetails = MessageModerationDetails(
            originalText: "original",
            action: .init(rawValue: "MESSAGE_RESPONSE_ACTION_BLOCK")
        )

        XCTAssertEqual(moderationDetails.action, .block)
    }
}
