//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ReadStateHandler_Tests: XCTestCase {
    private var client: ChatClient_Mock!
    private var authRepo: AuthenticationRepository_Mock!
    private var channelUpdater: ChannelUpdater_Mock!
    private var messageRepository: MessageRepository_Mock!

    private let userId = UserId.unique

    override func setUp() {
        super.setUp()
        client = ChatClient.mock
        authRepo = client.mockAuthenticationRepository
        authRepo.mockedCurrentUserId = userId
        channelUpdater = ChannelUpdater_Mock(
            channelRepository: client.channelRepository,
            messageRepository: client.messageRepository,
            paginationStateHandler: client.makeMessagesPaginationStateHandler(),
            database: client.databaseContainer,
            apiClient: client.apiClient
        )
        messageRepository = MessageRepository_Mock(
            database: client.databaseContainer,
            apiClient: client.apiClient
        )
    }

    override func tearDown() {
        client = nil
        authRepo = nil
        channelUpdater = nil
        messageRepository = nil
        super.tearDown()
    }

    // MARK: - markRead routing

    func test_markRead_localUnreadEnabled_readEventsDisabled_routesToLocalPath() {
        // GIVEN
        var config = ChatClientConfig(apiKeyString: "test")
        config.isLocalUnreadCountEnabled = true
        let handler = makeHandler(config: config)
        let channel = ChatChannel.mock(cid: .unique, config: .mock(readEventsEnabled: false))

        // WHEN
        handler.markRead(channel) { _ in }

        // THEN: local path is used, remote API is not called
        XCTAssertEqual(channelUpdater.markReadLocally_cid, channel.cid)
        XCTAssertEqual(channelUpdater.markReadLocally_userId, userId)
        XCTAssertNil(channelUpdater.markRead_cid)
    }

    func test_markRead_localUnreadEnabled_readEventsEnabled_routesToRemotePath() {
        // GIVEN
        var config = ChatClientConfig(apiKeyString: "test")
        config.isLocalUnreadCountEnabled = true
        let handler = makeHandler(config: config)
        let channel = ChatChannel.mock(cid: .unique, config: .mock(readEventsEnabled: true))

        // WHEN
        handler.markRead(channel) { _ in }

        // THEN: remote path is used because read events are enabled server-side
        XCTAssertEqual(channelUpdater.markRead_cid, channel.cid)
        XCTAssertNil(channelUpdater.markReadLocally_cid)
    }

    func test_markRead_localUnreadDisabled_readEventsDisabled_routesToRemotePath() {
        // GIVEN: flag is off — ignore readEventsEnabled, always use remote
        var config = ChatClientConfig(apiKeyString: "test")
        config.isLocalUnreadCountEnabled = false
        let handler = makeHandler(config: config)
        let channel = ChatChannel.mock(cid: .unique, config: .mock(readEventsEnabled: false))

        // WHEN
        handler.markRead(channel) { _ in }

        // THEN
        XCTAssertEqual(channelUpdater.markRead_cid, channel.cid)
        XCTAssertNil(channelUpdater.markReadLocally_cid)
    }

    func test_markRead_localUnreadDisabled_readEventsEnabled_routesToRemotePath() {
        // GIVEN: standard config, read events enabled
        var config = ChatClientConfig(apiKeyString: "test")
        config.isLocalUnreadCountEnabled = false
        let handler = makeHandler(config: config)
        let channel = ChatChannel.mock(cid: .unique, config: .mock(readEventsEnabled: true))

        // WHEN
        handler.markRead(channel) { _ in }

        // THEN
        XCTAssertEqual(channelUpdater.markRead_cid, channel.cid)
        XCTAssertNil(channelUpdater.markReadLocally_cid)
    }

    // MARK: - Completion forwarding on local path

    func test_markRead_localPath_forwardsSuccessCompletion() {
        // GIVEN
        var config = ChatClientConfig(apiKeyString: "test")
        config.isLocalUnreadCountEnabled = true
        channelUpdater.markReadLocally_completion_result = .success(())
        let handler = makeHandler(config: config)
        let channel = ChatChannel.mock(cid: .unique, config: .mock(readEventsEnabled: false))

        // WHEN
        let expectation = self.expectation(description: "completion called")
        nonisolated(unsafe) var receivedError: Error?
        handler.markRead(channel) { error in
            receivedError = error
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout)

        // THEN
        XCTAssertNil(receivedError)
    }

    func test_markRead_localPath_forwardsErrorCompletion() {
        // GIVEN
        var config = ChatClientConfig(apiKeyString: "test")
        config.isLocalUnreadCountEnabled = true
        let expectedError = TestError()
        channelUpdater.markReadLocally_completion_result = .failure(expectedError)
        let handler = makeHandler(config: config)
        let channel = ChatChannel.mock(cid: .unique, config: .mock(readEventsEnabled: false))

        // WHEN
        let expectation = self.expectation(description: "completion called")
        nonisolated(unsafe) var receivedError: Error?
        handler.markRead(channel) { error in
            receivedError = error
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout)

        // THEN
        XCTAssertEqual(receivedError as? TestError, expectedError)
    }

    func test_markRead_localPath_resetsIsMarkedAsUnread() {
        // GIVEN
        var config = ChatClientConfig(apiKeyString: "test")
        config.isLocalUnreadCountEnabled = true
        channelUpdater.markReadLocally_completion_result = .success(())
        let handler = makeHandler(config: config)
        let channel = ChatChannel.mock(cid: .unique, config: .mock(readEventsEnabled: false))

        // WHEN
        let expectation = self.expectation(description: "completion called")
        handler.markRead(channel) { _ in expectation.fulfill() }
        waitForExpectations(timeout: defaultTimeout)

        // THEN
        XCTAssertFalse(handler.isMarkedAsUnread)
    }

    // MARK: - Guard: no current user

    func test_markRead_noCurrentUser_doesNotCallEitherPath() {
        // GIVEN: no logged-in user
        authRepo.mockedCurrentUserId = nil
        var config = ChatClientConfig(apiKeyString: "test")
        config.isLocalUnreadCountEnabled = true
        let handler = makeHandler(config: config)
        let channel = ChatChannel.mock(cid: .unique, config: .mock(readEventsEnabled: false))

        // WHEN
        handler.markRead(channel) { _ in }

        // THEN: neither path is invoked
        XCTAssertNil(channelUpdater.markReadLocally_cid)
        XCTAssertNil(channelUpdater.markRead_cid)
    }

    // MARK: - Helpers

    private func makeHandler(config: ChatClientConfig) -> ReadStateHandler {
        ReadStateHandler(
            authenticationRepository: authRepo,
            channelUpdater: channelUpdater,
            messageRepository: messageRepository,
            config: config
        )
    }
}
