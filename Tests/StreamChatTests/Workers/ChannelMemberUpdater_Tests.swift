//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        nonisolated(unsafe) var completionCalled = false
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
        nonisolated(unsafe) var completionCalledError: Error?
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
        nonisolated(unsafe) var completionCalled = false
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
        nonisolated(unsafe) var completionCalledError: Error?
        updater.unbanMember(.unique, in: .unique) { error in
            completionCalledError = error
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Query banned users

    func test_queryBannedUsers_makesCorrectAPICall() {
        let query = BannedUserListQuery(filter: .equal(.cid, to: .unique))

        // Simulate `queryBannedUsers` call
        updater.queryBannedUsers(query: query) { _ in }

        // Assert correct endpoint is called
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(.queryBannedUsers(query: query)))
    }

    func test_queryBannedUsers_propagatesSuccessfulResponse() throws {
        let cid: ChannelId = .unique
        let bannedUserId: UserId = .unique
        let bannedById: UserId = .unique
        let createdAt: Date = .unique
        let expiresAt: Date = .unique
        let reason: String = .unique

        // Simulate `queryBannedUsers` call
        nonisolated(unsafe) var result: Result<[BannedUser], Error>?
        updater.queryBannedUsers(query: BannedUserListQuery()) { result = $0 }

        // Assert completion is not called yet
        XCTAssertNil(result)

        // Simulate API response with success
        apiClient.test_simulateResponse(
            Result<QueryBannedUsersResponse, Error>.success(
                .init(
                    bans: [
                        .dummy(
                            user: .dummy(userId: bannedUserId),
                            bannedBy: .dummy(userId: bannedById),
                            channel: .dummy(cid: cid),
                            createdAt: createdAt,
                            expires: expiresAt,
                            reason: reason,
                            shadow: true
                        )
                    ],
                    duration: "0.1ms"
                )
            )
        )

        // Assert the payload is mapped to models
        AssertAsync.willBeTrue(result != nil)
        let bans = try XCTUnwrap(result).get()
        XCTAssertEqual(bans.count, 1)
        XCTAssertEqual(bans.first?.user.id, bannedUserId)
        XCTAssertEqual(bans.first?.bannedBy?.id, bannedById)
        XCTAssertEqual(bans.first?.cid, cid)
        XCTAssertEqual(bans.first?.createdAt, createdAt)
        XCTAssertEqual(bans.first?.expiresAt, expiresAt)
        XCTAssertEqual(bans.first?.reason, reason)
        XCTAssertEqual(bans.first?.isShadowBan, true)
    }

    func test_queryBannedUsers_whenBanHasNoUser_thenBanIsSkipped() throws {
        // Simulate `queryBannedUsers` call
        nonisolated(unsafe) var result: Result<[BannedUser], Error>?
        updater.queryBannedUsers(query: BannedUserListQuery()) { result = $0 }

        // Simulate API response with a ban without a target user
        apiClient.test_simulateResponse(
            Result<QueryBannedUsersResponse, Error>.success(
                .init(bans: [.dummy(user: nil), .dummy()], duration: "0.1ms")
            )
        )

        // Assert only the ban with a user is returned
        AssertAsync.willBeTrue(result != nil)
        let bans = try XCTUnwrap(result).get()
        XCTAssertEqual(bans.count, 1)
    }

    func test_queryBannedUsers_propagatesError() {
        // Simulate `queryBannedUsers` call
        nonisolated(unsafe) var completionCalledError: Error?
        updater.queryBannedUsers(query: BannedUserListQuery()) { completionCalledError = $0.error }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<QueryBannedUsersResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Partial Update

    func test_partialUpdate_makesCorrectAPICall() {
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        let request = UpdateMemberPartialRequest(set: ["key": .string("value")], unset: ["field1"])

        // Simulate `partialUpdate` call
        updater.partialUpdate(
            userId: userId,
            in: cid,
            request: request,
            completion: { _ in }
        )

        // Assert correct endpoint is called
        XCTAssertEqual(
            apiClient.request_endpoint,
            AnyEndpoint(
                .updateMemberPartial(
                    type: cid.type.rawValue,
                    id: cid.id,
                    updateMemberPartialRequest: request
                )
            )
        )
    }

    func test_partialUpdate_propagatesSuccessfulResponse() {
        let cid: ChannelId = .unique
        let memberResponse: MemberPayload = .dummy()

        // Simulate `partialUpdate` call
        nonisolated(unsafe) var completionResult: Result<ChatChannelMember, Error>?
        updater.partialUpdate(
            userId: .unique,
            in: cid,
            request: UpdateMemberPartialRequest()
        ) { result in
            completionResult = result
        }

        // Simulate API response with success
        let response = UpdateMemberPartialResponse.dummy(channelMember: memberResponse)
        apiClient.test_simulateResponse(Result<UpdateMemberPartialResponse, Error>.success(response))

        // Assert completion is called with the member
        AssertAsync {
            Assert.willBeTrue(completionResult?.value?.id == memberResponse.userId)
        }
    }

    func test_partialUpdate_propagatesError() {
        // Simulate `partialUpdate` call
        nonisolated(unsafe) var completionResult: Result<ChatChannelMember, Error>?
        updater.partialUpdate(
            userId: .unique,
            in: .unique,
            request: UpdateMemberPartialRequest()
        ) { result in
            completionResult = result
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<UpdateMemberPartialResponse, Error>.failure(error))

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
        let apiResponse = UpdateMemberPartialResponse.dummy(
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
                .updateMemberPartial(
                    type: cid.type.rawValue,
                    id: cid.id,
                    updateMemberPartialRequest: UpdateMemberPartialRequest(set: ["pinned": .bool(true)], unset: nil)
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
        
        apiClient.test_mockResponseResult(Result<UpdateMemberPartialResponse, Error>.failure(error))
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
        
        let apiResponse = UpdateMemberPartialResponse.dummy(
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
                .updateMemberPartial(
                    type: cid.type.rawValue,
                    id: cid.id,
                    updateMemberPartialRequest: UpdateMemberPartialRequest(set: nil, unset: ["pinned"])
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
        
        apiClient.test_mockResponseResult(Result<UpdateMemberPartialResponse, Error>.failure(error))
        let resultingError = try waitFor { done in
            updater.pinMemberChannel(false, userId: userId, cid: cid, completion: done)
        }
        XCTAssertEqual(error, resultingError as? TestError, resultingError?.localizedDescription ?? "")
    }
    
    // MARK: - Archiving and Unarchiving Channels
    
    func test_archiving_makesCorrectAPICallAndUpdatesState() throws {
        let userId: UserId = .unique
        let anotherUserId: UserId = .unique
        let cid: ChannelId = .unique
        
        try database.createCurrentUser(id: userId)
        try database.createChannel(cid: cid)
        try database.createMember(userId: userId, cid: cid)
        try database.createMember(userId: anotherUserId, cid: cid)
        
        let archivedDate = Date()
        let apiResponse = UpdateMemberPartialResponse.dummy(
            channelMember: .dummy(
                user: .dummy(
                    userId: userId
                ),
                archivedAt: archivedDate
            )
        )
        apiClient.test_mockResponseResult(.success(apiResponse))
        let resultingError = try waitFor { done in
            updater.archiveMemberChannel(true, userId: userId, cid: cid, completion: done)
        }
        XCTAssertNil(resultingError, resultingError?.localizedDescription ?? "")
        XCTAssertEqual(
            apiClient.request_endpoint,
            AnyEndpoint(
                .updateMemberPartial(
                    type: cid.type.rawValue,
                    id: cid.id,
                    updateMemberPartialRequest: UpdateMemberPartialRequest(set: ["archived": .bool(true)], unset: nil)
                )
            )
        )
        // Assert member was updated
        try database.readSynchronously { session in
            guard let member = session.member(userId: userId, cid: cid) else { throw ClientError.MemberDoesNotExist(userId: userId, cid: cid) }
            XCTAssertNearlySameDate(archivedDate, member.archivedAt?.bridgeDate)
        }
    }
    
    func test_archiving_propagatesError() throws {
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        let error = TestError()
        
        apiClient.test_mockResponseResult(Result<UpdateMemberPartialResponse, Error>.failure(error))
        let resultingError = try waitFor { done in
            updater.archiveMemberChannel(true, userId: userId, cid: cid, completion: done)
        }
        XCTAssertEqual(error, resultingError as? TestError, resultingError?.localizedDescription ?? "")
    }
    
    func test_unarchiving_makesCorrectAPICallAndUpdatesState() throws {
        let userId: UserId = .unique
        let anotherUserId: UserId = .unique
        let cid: ChannelId = .unique
        
        try database.createCurrentUser(id: userId)
        try database.createChannel(cid: cid)
        try database.createMember(userId: userId, cid: cid, archivedAt: Date())
        try database.createMember(userId: anotherUserId, cid: cid)
        
        let apiResponse = UpdateMemberPartialResponse.dummy(
            channelMember: .dummy(
                user: .dummy(
                    userId: userId
                ),
                archivedAt: nil
            )
        )
        apiClient.test_mockResponseResult(.success(apiResponse))
        let resultingError = try waitFor { done in
            updater.archiveMemberChannel(false, userId: userId, cid: cid, completion: done)
        }
        XCTAssertNil(resultingError)
        XCTAssertEqual(
            apiClient.request_endpoint,
            AnyEndpoint(
                .updateMemberPartial(
                    type: cid.type.rawValue,
                    id: cid.id,
                    updateMemberPartialRequest: UpdateMemberPartialRequest(set: nil, unset: ["archived"])
                )
            )
        )
        // Assert member was updated
        try database.readSynchronously { session in
            guard let member = session.member(userId: userId, cid: cid) else { throw ClientError.MemberDoesNotExist(userId: userId, cid: cid) }
            XCTAssertNil(member.archivedAt)
        }
    }
    
    func test_unarchiving_propagatesError() throws {
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        let error = TestError()
        
        apiClient.test_mockResponseResult(Result<UpdateMemberPartialResponse, Error>.failure(error))
        let resultingError = try waitFor { done in
            updater.archiveMemberChannel(false, userId: userId, cid: cid, completion: done)
        }
        XCTAssertEqual(error, resultingError as? TestError, resultingError?.localizedDescription ?? "")
    }
}
