//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageSearchController_Debounce_Tests: XCTestCase {
    private var env: TestEnvironment!
    private var client: ChatClient!
    private var controller: ChatMessageSearchController!

    override func setUpWithError() throws {
        super.setUp()
        env = .init()
        client = ChatClient.mock
        client.authenticationRepository.setMockToken()
        controller = ChatMessageSearchController(client: client, environment: env.environment)
        controller.debouncePolicy = .constant(0.15)
    }

    override func tearDown() {
        env.messageUpdater?.cleanUp()
        (client as? ChatClient_Mock)?.cleanUp()
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
        }
        super.tearDown()
    }

    func test_search_shortQuery_isDebounced() {
        controller.search(text: "a")

        XCTAssertNil(env.messageUpdater?.search_query)

        let expectation = expectation(description: "Debounced search fires")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertNotNil(self.env.messageUpdater?.search_query)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_search_rapidTyping_cancelsPreviousRequest() {
        controller.search(text: "a")
        controller.search(text: "ab")
        controller.search(text: "abc")

        XCTAssertNil(env.messageUpdater?.search_query)

        let expectation = expectation(description: "Only latest search fires")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            XCTAssertEqual(
                self.env.messageUpdater?.search_query?.messageFilter.value as? String,
                "abc"
            )
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_search_emptyText_isImmediateAndCancelsPending() {
        controller.search(text: "a")
        controller.search(text: "")

        XCTAssertNil(env.messageUpdater?.search_query)

        let expectation = expectation(description: "Pending short query does not fire")
        expectation.isInverted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if self.env.messageUpdater?.search_query != nil {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 0.4)
    }

    func test_debouncePolicy_canBeOverriddenPerController() {
        controller.debouncePolicy = .constant(0)
        controller.search(text: "a")
        XCTAssertNotNil(env.messageUpdater?.search_query)
    }
}

private class TestEnvironment {
    @Atomic var messageUpdater: MessageUpdater_Mock?

    lazy var environment: ChatMessageSearchController.Environment =
        .init(messageUpdaterBuilder: { [unowned self] in
            self.messageUpdater = MessageUpdater_Mock(
                isLocalStorageEnabled: $0,
                messageRepository: $1,
                database: $2,
                apiClient: $3
            )
            return self.messageUpdater!
        })
}
