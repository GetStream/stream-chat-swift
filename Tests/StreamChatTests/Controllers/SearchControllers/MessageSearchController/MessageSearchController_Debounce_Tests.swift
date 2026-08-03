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
        controller = makeController(debouncePolicy: .constant(0.15))
    }

    private func makeController(debouncePolicy: SearchDebouncePolicy) -> ChatMessageSearchController {
        ChatMessageSearchController(
            client: client,
            environment: env.environment,
            debouncePolicy: debouncePolicy
        )
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
        controller = makeController(debouncePolicy: .constant(0))
        controller.search(text: "a")
        XCTAssertNotNil(env.messageUpdater?.search_query)
    }

    func test_search_withQueryWithoutSearchText_isNotDebounced() {
        let query = MessageSearchQuery(
            channelFilter: .containMembers(userIds: [.unique]),
            messageFilter: .withAttachments([.image])
        )

        controller.search(query: query)

        // A query with no search text is not typed character by character, so it runs right
        // away even though the controller has a non-zero debounce interval.
        XCTAssertNotNil(env.messageUpdater?.search_query)
    }

    func test_search_withCustomQueryContainingSearchText_isDebounced() {
        // A custom query that combines a text search with other filters is still typed
        // character by character, so it must be debounced on the search text length.
        let query = MessageSearchQuery(
            channelFilter: .containMembers(userIds: [.unique]),
            messageFilter: .and([
                .autocomplete(.text, text: "ab"),
                .withAttachments([.image])
            ])
        )

        controller.search(query: query)

        XCTAssertNil(env.messageUpdater?.search_query)

        let expectation = expectation(description: "Debounced custom query fires")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertNotNil(self.env.messageUpdater?.search_query)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_search_withCustomQueryContainingShortSearchText_respectsMinimumCharacterCount() {
        controller = makeController(debouncePolicy: .constant(0, minimumCharacterCount: 3))
        let query = MessageSearchQuery(
            channelFilter: .containMembers(userIds: [.unique]),
            messageFilter: .and([
                .autocomplete(.text, text: "ab"),
                .withAttachments([.image])
            ])
        )

        controller.search(query: query)

        XCTAssertNil(env.messageUpdater?.search_query)
    }

    func test_search_belowMinimumCharacterCount_doesNotFireRequest() {
        controller = makeController(debouncePolicy: .constant(0, minimumCharacterCount: 3))

        let expectation = expectation(description: "Completion called when search is skipped")
        controller.search(text: "ab") { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertNil(env.messageUpdater?.search_query)
    }

    func test_search_belowMinimumCharacterCount_cancelsPendingDebouncedSearch() {
        controller = makeController(
            debouncePolicy: SearchDebouncePolicy(
                thresholds: [.init(maximumCharacterCount: .max, interval: 0.2)],
                minimumCharacterCount: 3
            )
        )

        controller.search(text: "abc")
        controller.search(text: "ab")

        XCTAssertNil(env.messageUpdater?.search_query)

        let expectation = expectation(description: "Pending search above minimum does not fire")
        expectation.isInverted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if self.env.messageUpdater?.search_query != nil {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 0.5)
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
