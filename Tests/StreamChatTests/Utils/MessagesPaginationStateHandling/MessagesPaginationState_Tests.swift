//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class MessagesPaginationState_Tests: XCTestCase {
    func test_initial() {
        let sut = MessagesPaginationState.initial
        XCTAssertEqual(sut.hasLoadedAllNextMessages, true)
        XCTAssertEqual(sut.hasLoadedAllPreviousMessages, false)
        XCTAssertEqual(sut.isLoadingNextMessages, false)
        XCTAssertEqual(sut.isLoadingPreviousMessages, false)
        XCTAssertEqual(sut.isLoadingMiddleMessages, false)
        XCTAssertNil(sut.oldestFetchedMessage)
        XCTAssertNil(sut.newestFetchedMessage)
    }

    func test_oldestMessageAt() {
        let expectedOldestMessageAt = Date.unique
        var sut = MessagesPaginationState.initial
        sut.oldestFetchedMessage = .dummy(createdAt: expectedOldestMessageAt)
        XCTAssertEqual(sut.oldestMessageAt, expectedOldestMessageAt)
    }

    func test_newestMessageAt() {
        let expectedNewestMessageAt = Date.unique
        var sut = MessagesPaginationState.initial
        sut.newestFetchedMessage = .dummy(createdAt: expectedNewestMessageAt)
        XCTAssertEqual(sut.newestMessageAt, expectedNewestMessageAt)
    }

    func test_isJumpingToMessages_whenHasLoadedAllNextMessage_thenReturnsFalse() {
        var sut = MessagesPaginationState.initial
        sut.hasLoadedAllNextMessages = true
        XCTAssertEqual(sut.isJumpingToMessage, false)
    }

    func test_isJumpingToMessages_whenHasNotLoadedAllNextMessage_thenReturnsTrue() {
        var sut = MessagesPaginationState.initial
        sut.hasLoadedAllNextMessages = false
        XCTAssertEqual(sut.isJumpingToMessage, true)
    }

    func test_hasLoadedAllNextMessages_whenChangesToTrue_thenNewestFetchedMessageIsNil() {
        var sut = MessagesPaginationState.initial
        sut.newestFetchedMessage = .dummy()

        sut.hasLoadedAllNextMessages = true

        XCTAssertNil(sut.newestFetchedMessage)
    }

    func test_hasLoadedAllNextMessages_whenChangesToFalse_thenDoesNotChangeNewestFetchedMessageIsNil() {
        let expectedNewestFetchedMessage = MessagePayload.dummy()
        var sut = MessagesPaginationState.initial
        sut.newestFetchedMessage = expectedNewestFetchedMessage

        sut.hasLoadedAllNextMessages = false

        XCTAssertEqual(sut.newestFetchedMessage?.id, expectedNewestFetchedMessage.id)
    }

    func test_isLoadingMessages_whenNotLoadingNextOrPreviousOrMiddlesMessages_thenReturnsFalse() {
        var sut = MessagesPaginationState.initial
        sut.isLoadingNextMessages = false
        sut.isLoadingMiddleMessages = false
        sut.isLoadingPreviousMessages = false
        XCTAssertEqual(sut.isLoadingMessages, false)
    }

    func test_isLoadingMessages_whenLoadingNextMessages_thenReturnsTrue() {
        var sut = MessagesPaginationState.initial
        sut.isLoadingNextMessages = true
        sut.isLoadingMiddleMessages = false
        sut.isLoadingPreviousMessages = false
        XCTAssertEqual(sut.isLoadingMessages, true)
    }

    func test_isLoadingMessages_whenLoadingPreviousMessages_thenReturnsTrue() {
        var sut = MessagesPaginationState.initial
        sut.isLoadingNextMessages = false
        sut.isLoadingMiddleMessages = false
        sut.isLoadingPreviousMessages = true
        XCTAssertEqual(sut.isLoadingMessages, true)
    }

    func test_isLoadingMessages_whenLoadingMiddleMessages_thenReturnsTrue() {
        var sut = MessagesPaginationState.initial
        sut.isLoadingNextMessages = false
        sut.isLoadingMiddleMessages = true
        sut.isLoadingPreviousMessages = false
        XCTAssertEqual(sut.isLoadingMessages, true)
    }
}
