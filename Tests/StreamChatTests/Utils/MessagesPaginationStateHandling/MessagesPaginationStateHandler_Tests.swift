//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class MessagesPaginationStateHandlerTests: XCTestCase {
    var sut: MessagesPaginationStateHandler!

    override func setUp() {
        super.setUp()
        sut = MessagesPaginationStateHandler()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - begin

    func test_begin_whenLoadingPreviousMessages_thenSetsStateToLoadingPreviousMessages() {
        // Given
        sut.state.isLoadingPreviousMessages = false
        let pagination = MessagesPagination(pageSize: 10, parameter: .lessThan("123"))

        // When
        sut.begin(pagination: pagination)

        // Then
        XCTAssertTrue(sut.state.isLoadingPreviousMessages)
    }

    func test_begin_whenLoadingNextMessages_thenSetsStateToLoadingNextMessages() {
        // Given
        sut.state.isLoadingNextMessages = false
        let pagination = MessagesPagination(pageSize: 10, parameter: .greaterThan("123"))

        // When
        sut.begin(pagination: pagination)

        // Then
        XCTAssertTrue(sut.state.isLoadingNextMessages)
    }

    func test_begin_whenLoadingMiddleMessages_thenSetsStateToLoadingMiddleMessages() {
        // Given
        sut.state.isLoadingMiddleMessages = false
        let pagination = MessagesPagination(pageSize: 10, parameter: .around("123"))

        // When
        sut.begin(pagination: pagination)

        // Then
        XCTAssertTrue(sut.state.isLoadingMiddleMessages)
    }

    func test_begin_whenJumpingToMessage_thenSetsHasLoadedAllNextMessagesToFalse() {
        // Given
        sut.state.hasLoadedAllNextMessages = true
        let pagination = MessagesPagination(pageSize: 10, parameter: .around("123"))

        // When
        sut.begin(pagination: pagination)

        // Then
        XCTAssertFalse(sut.state.hasLoadedAllNextMessages)
    }

    func test_begin_whenLoadingFirstPage_thenSetsStateToInitial() {
        // Given
        sut.state.isLoadingNextMessages = true
        sut.state.hasLoadedAllNextMessages = false
        sut.state.oldestFetchedMessage = .dummy()
        let pagination = MessagesPagination(pageSize: 10, parameter: nil)

        // When
        sut.begin(pagination: pagination)

        // Then
        XCTAssertEqual(sut.state, .initial)
    }

    // MARK: - end

    func test_end_whenLoadingPreviousMessages_thenSetsOldestFetchedMessage() {
        // Given
        let pagination = MessagesPagination(pageSize: 10, parameter: .lessThan("123"))
        let messages: [MessagePayload] = [
            .dummy(messageId: "111"),
            .dummy(messageId: "112"),
            .dummy(messageId: "113")
        ]

        // When
        sut.end(pagination: pagination, with: .success(messages))

        // Then
        XCTAssertEqual(sut.state.oldestFetchedMessage?.id, "111")
    }

    func test_end_whenLoadingPreviousMessagesAndResultIsLowerThanPageSize_thenSetsHasLoadedAllPreviousMessagesToTrue() {
        // Given
        sut.state.hasLoadedAllPreviousMessages = false
        let pagination = MessagesPagination(pageSize: 10, parameter: .lessThan("123"))

        // When
        sut.end(pagination: pagination, with: .success([.dummy(), .dummy()]))

        // Then
        XCTAssertTrue(sut.state.hasLoadedAllPreviousMessages)
    }

    func test_end_whenLoadingNextMessages_thenSetsNewestFetchedMessage() {
        // Given
        let pagination = MessagesPagination(pageSize: 2, parameter: .greaterThan("123"))
        let messages: [MessagePayload] = [.dummy(), .dummy(), .dummy(messageId: "126")]

        // When
        sut.end(pagination: pagination, with: .success(messages))

        // Then
        XCTAssertEqual(sut.state.newestFetchedMessage?.id, "126")
    }

    func test_end_whenLoadingNextMessagesAndResultIsLowerThanPageSize_thenResetsNewestFetchedMessageAndSetsHasLoadedAllNextMessagesToTrue() {
        // Given
        sut.state.hasLoadedAllNextMessages = false
        sut.state.newestFetchedMessage = .dummy()
        let pagination = MessagesPagination(pageSize: 10, parameter: .greaterThan("123"))

        // When
        sut.end(pagination: pagination, with: .success([.dummy(), .dummy()]))

        // Then
        XCTAssertTrue(sut.state.hasLoadedAllNextMessages)
        XCTAssertNil(sut.state.newestFetchedMessage)
    }

    func test_end_whenLoadingMiddleMessages_thenSetsOldestFetchedMessageToFirstMessageAndNewestFetchedMessageToLastMessage() {
        // Given
        let pagination = MessagesPagination(pageSize: 5, parameter: .around("123"))
        let messages: [MessagePayload] = [.dummy(messageId: "121"), .dummy(messageId: "122"), .dummy(messageId: "123"), .dummy(messageId: "124"), .dummy(messageId: "125")]

        // When
        sut.end(pagination: pagination, with: .success(messages))

        // Then
        XCTAssertEqual(sut.state.oldestFetchedMessage?.id, "121")
        XCTAssertEqual(sut.state.newestFetchedMessage?.id, "125")
    }

    func test_end_whenLoadingMiddleMessagesAndResultIsLowerThanPageSize_thenSetsHasLoadedAllPreviousMessagesAndHasLoadedAllNextMessagesToTrue() {
        // Given
        sut.state.hasLoadedAllPreviousMessages = false
        sut.state.hasLoadedAllNextMessages = false
        let pagination = MessagesPagination(pageSize: 5, parameter: .around("123"))

        // When
        sut.end(pagination: pagination, with: .success([.dummy(), .dummy()]))

        // Then
        XCTAssertTrue(sut.state.hasLoadedAllPreviousMessages)
        XCTAssertTrue(sut.state.hasLoadedAllNextMessages)
    }

    func test_end_whenResultIsError_thenDoesNotChangePreviousState() {
        // Given
        let pagination = MessagesPagination(pageSize: 10, parameter: .around("123"))
        sut.end(pagination: pagination, with: .success([.dummy(), .dummy()]))
        let stateBefore = sut.state
        XCTAssertNotNil(stateBefore.oldestFetchedMessage)
        XCTAssertNotNil(stateBefore.newestFetchedMessage)

        // When
        sut.end(pagination: pagination, with: .failure(NSError(domain: "test", code: 0)))

        // Then
        XCTAssertEqual(sut.state, stateBefore)
    }
}

extension MessagesPaginationState: Equatable {
    public static func == (lhs: MessagesPaginationState, rhs: MessagesPaginationState) -> Bool {
        lhs.hasLoadedAllNextMessages == rhs.hasLoadedAllNextMessages &&
            lhs.hasLoadedAllPreviousMessages == rhs.hasLoadedAllPreviousMessages &&
            lhs.isLoadingMiddleMessages == rhs.isLoadingMiddleMessages &&
            lhs.isLoadingPreviousMessages == rhs.isLoadingPreviousMessages &&
            lhs.isLoadingNextMessages == rhs.isLoadingNextMessages &&
            lhs.oldestFetchedMessage?.id == rhs.oldestFetchedMessage?.id &&
            lhs.newestFetchedMessage?.id == rhs.newestFetchedMessage?.id
    }
}
