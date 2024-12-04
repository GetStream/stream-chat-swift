//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelMemberUpdater_Tests: XCTestCase {
    var webSocketClient: WebSocketClient_Mock!
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!

    var updater: ChannelMemberUpdater!

    // MARK: Setup

    override func setUp() {
        super.setUp()

        webSocketClient = WebSocketClient_Mock()
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()

        updater = .init(database: database, apiClient: apiClient)
    }

    override func tearDown() {
        apiClient.cleanUp()
        AssertAsync {
            Assert.canBeReleased(&updater)
            Assert.canBeReleased(&webSocketClient)
            Assert.canBeReleased(&apiClient)
            Assert.canBeReleased(&database)
        }

        super.tearDown()
    }

    // MARK: - Ban user

    func test_banMember_makesCorrectAPICall() {
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        let timeoutInMinutes = 15
        let reason: String = .unique

        // Simulate `banMember` call
        updater.banMember(userId, in: cid, shadow: false, for: timeoutInMinutes, reason: reason)

        // Assert correct endpoint is called
        XCTAssertEqual(
            apiClient.request_endpoint,
            AnyEndpoint(
                .banMember(userId, cid: cid, shadow: false, timeoutInMinutes: timeoutInMinutes, reason: reason)
            )
        )
    }

    func test_banMember_propagatesSuccessfulResponse() {
        // Simulate `banMember` call
        var completionCalled = false
        updater.banMember(.unique, in: .unique, shadow: false) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_banMember_propagatesError() {
        // Simulate `banMember` call
        var completionCalledError: Error?
        updater.banMember(.unique, in: .unique, shadow: false) { error in
            completionCalledError = error
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Unban user

    func test_unbanMember_makesCorrectAPICall() {
        let userId: UserId = .unique
        let cid: ChannelId = .unique

        // Simulate `unbanMember` call
        updater.unbanMember(userId, in: cid)

        // Assert correct endpoint is called
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(.unbanMember(userId, cid: cid)))
    }

    func test_unbanMember_propagatesSuccessfulResponse() {
        // Simulate `unbanMember` call
        var completionCalled = false
        updater.unbanMember(.unique, in: .unique) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_unbanMember_propagatesError() {
        // Simulate `unbanMember` call
        var completionCalledError: Error?
        updater.unbanMember(.unique, in: .unique) { error in
            completionCalledError = error
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Partial Update

    func test_partialUpdate_makesCorrectAPICall() {
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        let extraData: [String: RawJSON] = ["key": .string("value")]
        let unset: [String] = ["field1"]

        // Simulate `partialUpdate` call
        updater.partialUpdate(
            userId: userId,
            in: cid,
            extraData: extraData,
            unset: unset,
            completion: { _ in }
        )

        // Assert correct endpoint is called
        XCTAssertEqual(
            apiClient.request_endpoint,
            AnyEndpoint(
                .partialMemberUpdate(
                    userId: userId,
                    cid: cid,
                    extraData: extraData,
                    unset: unset
                )
            )
        )
    }

    func test_partialUpdate_propagatesSuccessfulResponse() {
        let cid: ChannelId = .unique
        let memberPayload: MemberPayload = .dummy()

        // Simulate `partialUpdate` call
        var completionResult: Result<ChatChannelMember, Error>?
        updater.partialUpdate(
            userId: .unique,
            in: cid,
            extraData: nil,
            unset: nil
        ) { result in
            completionResult = result
        }

        // Simulate API response with success
        let response = PartialMemberUpdateResponse(channelMember: memberPayload)
        apiClient.test_simulateResponse(Result<PartialMemberUpdateResponse, Error>.success(response))

        // Assert completion is called with the member
        AssertAsync {
            Assert.willBeTrue(completionResult?.value?.id == memberPayload.userId)
        }
    }

    func test_partialUpdate_propagatesError() {
        // Simulate `partialUpdate` call
        var completionResult: Result<ChatChannelMember, Error>?
        updater.partialUpdate(
            userId: .unique,
            in: .unique,
            extraData: nil,
            unset: nil
        ) { result in
            completionResult = result
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<PartialMemberUpdateResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync {
            Assert.willBeTrue(completionResult?.isError == true)
            Assert.willBeEqual(completionResult?.error as? TestError, error)
        }
    }
    
    // MARK: - Pinning and Unpinning Channels

    func test_pin_makesCorrectAPICallAndUpdatesState() throws {
        let userId: UserId = .unique
        let anotherUserId: UserId = .unique
        let cid: ChannelId = .unique
        
        try database.createCurrentUser(id: userId)
        try database.createChannel(cid: cid)
        try database.createMember(userId: userId, cid: cid)
        try database.createMember(userId: anotherUserId, cid: cid)
        
        let pinnedDate = Date()
        let apiResponse = PartialMemberUpdateResponse(
            channelMember: .dummy(
                user: .dummy(
                    userId: userId
                ),
                pinnedAt: pinnedDate
            )
        )
        apiClient.test_mockResponseResult(.success(apiResponse))
        let resultingError = try waitFor { done in
            updater.pinMemberChannel(true, userId: userId, cid: cid, completion: done)
        }
        XCTAssertNil(resultingError, resultingError?.localizedDescription ?? "")
        XCTAssertEqual(
            apiClient.request_endpoint,
            AnyEndpoint(
                .partialMemberUpdate(
                    userId: userId,
                    cid: cid,
                    extraData: ["pinned": .bool(true)],
                    unset: nil
                )
            )
        )
        // Assert member was updated
        try database.readSynchronously { session in
            guard let member = session.member(userId: userId, cid: cid) else { throw ClientError.MemberDoesNotExist(userId: userId, cid: cid) }
            XCTAssertNearlySameDate(pinnedDate, member.pinnedAt?.bridgeDate)
        }
    }
    
    func test_pin_propagatesError() throws {
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        let error = TestError()
        
        apiClient.test_mockResponseResult(Result<PartialMemberUpdateResponse, Error>.failure(error))
        let resultingError = try waitFor { done in
            updater.pinMemberChannel(true, userId: userId, cid: cid, completion: done)
        }
        XCTAssertEqual(error, resultingError as? TestError, resultingError?.localizedDescription ?? "")
    }
    
    func test_unpin_makesCorrectAPICallAndUpdatesState() throws {
        let userId: UserId = .unique
        let anotherUserId: UserId = .unique
        let cid: ChannelId = .unique
        
        try database.createCurrentUser(id: userId)
        try database.createChannel(cid: cid)
        try database.createMember(userId: userId, cid: cid)
        try database.createMember(userId: anotherUserId, cid: cid)
        
        let apiResponse = PartialMemberUpdateResponse(
            channelMember: .dummy(
                user: .dummy(
                    userId: userId
                ),
                pinnedAt: nil
            )
        )
        apiClient.test_mockResponseResult(.success(apiResponse))
        let resultingError = try waitFor { done in
            updater.pinMemberChannel(false, userId: userId, cid: cid, completion: done)
        }
        XCTAssertNil(resultingError)
        XCTAssertEqual(
            apiClient.request_endpoint,
            AnyEndpoint(
                .partialMemberUpdate(
                    userId: userId,
                    cid: cid,
                    extraData: nil,
                    unset: ["pinned"]
                )
            )
        )
        // Assert member was updated
        try database.readSynchronously { session in
            guard let member = session.member(userId: userId, cid: cid) else { throw ClientError.MemberDoesNotExist(userId: userId, cid: cid) }
            XCTAssertNil(member.pinnedAt)
        }
    }
    
    func test_unpin_propagatesError() throws {
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        let error = TestError()
        
        apiClient.test_mockResponseResult(Result<PartialMemberUpdateResponse, Error>.failure(error))
        let resultingError = try waitFor { done in
            updater.pinMemberChannel(false, userId: userId, cid: cid, completion: done)
        }
        XCTAssertEqual(error, resultingError as? TestError, resultingError?.localizedDescription ?? "")
    }
}
