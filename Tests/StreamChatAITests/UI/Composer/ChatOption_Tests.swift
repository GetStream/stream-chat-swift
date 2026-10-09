//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class ChatOption_Tests: XCTestCase {
    func test_equality_whenIDsMatch_isEqual() {
        let option = ChatOption(id: "search", title: "Search", description: "Search the web", icon: "globe", shortTitle: "Search")
        let renamed = ChatOption(id: "search", title: "Web", description: "Look it up", icon: "magnifyingglass", shortTitle: "Web")

        XCTAssertEqual(option, renamed)
    }

    func test_equality_whenIDsDiffer_isNotEqual() {
        let search = ChatOption(id: "search", title: "Search", description: "Search the web", icon: "globe", shortTitle: "Search")
        let image = ChatOption(id: "image", title: "Search", description: "Search the web", icon: "globe", shortTitle: "Search")

        XCTAssertNotEqual(search, image)
    }

    func test_messageData_defaultsToNoAttachmentsAndNoOption() {
        let message = MessageData(text: "Hello")

        XCTAssertEqual(message.text, "Hello")
        XCTAssertTrue(message.attachments.isEmpty)
        XCTAssertNil(message.chatOption)
    }
}
