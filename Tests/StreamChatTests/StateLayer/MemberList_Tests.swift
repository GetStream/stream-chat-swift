//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MemberList_Tests: XCTestCase {
    private var channelId: ChannelId!
    @MainActor private var memberList: MemberList!
    private var env: TestEnvironment!
    private var query: ChannelMemberListQuery!
    
    override func setUpWithError() throws {
        channelId = .unique
        env = TestEnvironment()
        query = .init(
            cid: channelId,
            sort: [.init(key: .name, isAscending: true)]
        )
    }

    @MainActor override func tearDownWithError() throws {
        env.cleanUp()
        env = nil
        memberList = nil
        query = nil
    }
    
    // MARK: - Restoring State

    func test_restoreState_whenDatabaseHasItems_thenStateIsUpToDate() async throws {
        try await createChannel()
        let initialPayload = makeMemberListPayload(count: 5, offset: 0)
        try await env.client.databaseContainer.write { session in
            session.saveMembers(
                payload: initialPayload,
                channelId: self.channelId,
                query: self.query
            )
        }
        try await setUpMemberList(usesMockedUpdater: false)
        await XCTAssertEqual(initialPayload.members.map(\.user?.id), memberList.state.members.map(\.id))
    }

    // MARK: - Get
    
    func test_get_whenLocalStoreHasMembers_thenGetResetsMembers() async throws {
        // Existing state
        try await createChannel()
        let initialPayload = makeMemberListPayload(count: 10, offset: 0)
        try await env.client.mockDatabaseContainer.write { session in
            session.saveMembers(
                payload: initialPayload,
                channelId: self.channelId,
                query: self.query
            )
        }
        
        try await setUpMemberList(usesMockedUpdater: false)
        await XCTAssertEqual(10, memberList.state.members.count)
        
        let nextPayload = makeMemberListPayload(count: 3, offset: 0)
        env.client.mockAPIClient.test_mockResponseResult(.success(nextPayload))
        try await memberList.get()
        
        await XCTAssertEqual(3, memberList.state.members.count)
        await XCTAssertEqual(nextPayload.members.map(\.user?.id), memberList.state.members.map(\.id))
    }
    
    func test_get_whenLocalStoreHasNoMembers_thenGetFetchesFirstPageOfMembers() async throws {
        try await createChannel()
        try await setUpMemberList(usesMockedUpdater: false)
        await XCTAssertEqual(0, memberList.state.members.count)
        
        let nextPayload = makeMemberListPayload(count: 3, offset: 0)
        env.client.mockAPIClient.test_mockResponseResult(.success(nextPayload))
        try await memberList.get()
        
        await XCTAssertEqual(3, memberList.state.members.count)
        await XCTAssertEqual(nextPayload.members.map(\.user?.id), memberList.state.members.map(\.id))
    }
    
    // MARK: - Pagination
    
    func test_loadMembers_whenAPIRequestSucceeds_thenResultsAreReturnedAndStateUpdates() async throws {
        try await createChannel()
        try await setUpMemberList(usesMockedUpdater: false)
        
        let apiResult = makeMemberListPayload(count: 10, offset: 0)
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResult))
        let pagination = Pagination(pageSize: 10)
        let result = try await memberList.loadMembers(with: pagination)
        XCTAssertEqual(apiResult.members.map(\.user?.id), result.map(\.id))
        await XCTAssertEqual(apiResult.members.map(\.user?.id), memberList.state.members.map(\.id))
    }
    
    func test_loadMoreMembers_whenAPIRequestSucceeds_thenResultsAreReturnedAndStateUpdates() async throws {
        try await createChannel()
        try await setUpMemberList(usesMockedUpdater: false)
        
        let initialPayload = makeMemberListPayload(count: 5, offset: 0)
        try await env.client.databaseContainer.write { session in
            session.saveMembers(
                payload: initialPayload,
                channelId: self.channelId,
                query: self.query
            )
        }
        
        let apiResult = makeMemberListPayload(count: 3, offset: 5)
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResult))
        let result = try await memberList.loadMoreMembers(limit: 3)
        XCTAssertEqual(apiResult.members.map(\.user?.id), result.map(\.id))
        let allExpectedIds = (initialPayload.members + apiResult.members).map(\.user?.id)
        await XCTAssertEqual(allExpectedIds, memberList.state.members.map(\.id))
    }

    // MARK: - Test Data
    
    @MainActor private func setUpMemberList(usesMockedUpdater: Bool, loadState: Bool = true) async throws {
        memberList = MemberList(
            query: query,
            client: env.client,
            environment: env.memberListEnvironment(usesMockedUpdater: usesMockedUpdater)
        )
        if loadState {
            _ = memberList.state
        }
    }
    
    private func createChannel() async throws {
        try await env.client.databaseContainer.write { session in
            try session.saveChannel(
                payload: ChannelPayload.dummy(
                    channel: .dummy(cid: self.channelId)
                )
            )
        }
    }
    
    private func makeMemberListPayload(count: Int, offset: Int) -> ChannelMemberListPayload {
        let members = (0..<count)
            .map { $0 + offset }
            .map {
                MemberPayload.dummy(
                    user: .dummy(
                        userId: String(format: "%03d", $0),
                        name: String(format: "%03d", $0)
                    )
                )
            }
        return ChannelMemberListPayload(members: members)
    }
}

extension MemberList_Tests {
    final class TestEnvironment {
        let client: ChatClient_Mock
        private(set) var memberListUpdater: ChannelMemberListUpdater!
        private(set) var memberListUpdaterMock: ChannelMemberListUpdater_Mock!
        
        func cleanUp() {
            client.cleanUp()
            memberListUpdaterMock?.cleanUp()
        }
        
        init() {
            client = ChatClient_Mock(
                config: ChatClient_Mock.defaultMockedConfig
            )
        }
        
        func memberListEnvironment(usesMockedUpdater: Bool) -> MemberList.Environment {
            MemberList.Environment(
                memberListUpdaterBuilder: { [unowned self] in
                    self.memberListUpdater = ChannelMemberListUpdater(
                        database: $0,
                        apiClient: $1
                    )
                    self.memberListUpdaterMock = ChannelMemberListUpdater_Mock(
                        database: $0,
                        apiClient: $1
                    )
                    return usesMockedUpdater ? memberListUpdaterMock : memberListUpdater
                }
            )
        }
    }
}
