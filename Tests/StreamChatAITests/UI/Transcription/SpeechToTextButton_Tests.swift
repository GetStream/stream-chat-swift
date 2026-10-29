//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamChatAI
import XCTest

@MainActor
final class SpeechToTextButton_Tests: XCTestCase {
    func test_transcripts_skipTheCurrentValueAndEmptyOnes() {
        let handler = SpeechHandler()
        handler.transcript = "Said before the button appeared"
        var received: [String] = []

        let cancellable = SpeechToTextButton.transcripts(handler.$transcript).sink { received.append($0) }
        handler.transcript = ""
        handler.transcript = "Hello"
        handler.transcript = ""
        handler.transcript = "Hello there"
        cancellable.cancel()

        XCTAssertEqual(received, ["Hello", "Hello there"])
    }
}
