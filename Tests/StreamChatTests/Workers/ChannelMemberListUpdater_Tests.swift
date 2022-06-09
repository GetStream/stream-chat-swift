//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelMemberListUpdater_Tests: XCTestCase {
    var webSocketClient: WebSocketClient_Mock!
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!
    var query: ChannelMemberListQuery!

    var listUpdater: ChannelMemberListUpdater!
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClient_Mock()
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        query = .init(cid: .unique, filter: .query(.id, text: "Luke"))

        listUpdater = .init(database: database, apiClient: apiClient)
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        AssertAsync {
            Assert.canBeReleased(&listUpdater)
            Assert.canBeReleased(&webSocketClient)
            Assert.canBeReleased(&apiClient)
            Assert.canBeReleased(&database)
        }

        query = nil
        super.tearDown()
    }
    
    // MARK: - Load
    
    func test_load_happyPath_whenChannelExistsLocally() throws {
        // Save channel to the database.
        try database.createChannel(cid: query.cid)
        
        // Simulate `load` call.
        var completionCalled = false
        listUpdater.load(query) { error in
            XCTAssertNil(error)
            completionCalled = true
        }
        
        // Assert members endpoint is called.
        let membersEndpoint: Endpoint<ChannelMemberListPayload> = .channelMembers(query: query)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(membersEndpoint))
        
        // Simulate members response.
        let payload = ChannelMemberListPayload(members: [
            .dummy(user: .dummy(userId: .unique)),
            .dummy(user: .dummy(userId: .unique)),
            .dummy(user: .dummy(userId: .unique))
        ])
        apiClient.test_simulateResponse(.success(payload))
        
        AssertAsync.willBeTrue(completionCalled)
        
        // Load query.
        var queryDTO: ChannelMemberListQueryDTO? {
            database.viewContext.channelMemberListQuery(queryHash: query.queryHash)
        }
        
        AssertAsync {
            // Assert query is saved to the database.
            Assert.willBeTrue(queryDTO != nil)
            // Assert query members are saved to the database.
            Assert.willBeEqual(Set(queryDTO?.members.map(\.user.id) ?? []), Set(payload.members.map(\.user.id)))
        }
    }
    
    func test_load_happyPath_whenChannelDoesNotExistsLocally() {
        // Simulate `load` call.
        var completionCalled = false
        listUpdater.load(query) { error in
            XCTAssertNil(error)
            completionCalled = true
        }
        
        // Assert channel endpoint is called.
        let channelEndpoint: Endpoint<ChannelPayload> = .updateChannel(query: .init(cid: query.cid))
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(channelEndpoint))
        
        // Simulate successful channel response.
        let dummyChannelPayload = dummyPayload(with: query.cid)
        apiClient.test_simulateResponse(.success(dummyChannelPayload))
        
        let membersEndpoint: Endpoint<ChannelMemberListPayload> = .channelMembers(query: query)
        AssertAsync {
            // Assert members endpoint is called.
            Assert.willBeEqual(self.apiClient.request_endpoint, AnyEndpoint(membersEndpoint))
        }
        
        // Simulate members response.
        let payload = ChannelMemberListPayload(members: [
            .dummy(user: .dummy(userId: .unique)),
            .dummy(user: .dummy(userId: .unique)),
            .dummy(user: .dummy(userId: .unique))
        ])
        apiClient.test_simulateResponse(.success(payload))
        
        // Assert completion is called.
        AssertAsync.willBeTrue(completionCalled)
        
        // Load query.
        var queryDTO: ChannelMemberListQueryDTO? {
            FetchCache.clear()
            return database.viewContext.channelMemberListQuery(queryHash: query.queryHash)
        }
        
        // Load channel.
        var channelDTO: ChannelDTO? {
            FetchCache.clear()
            return database.viewContext.channel(cid: query.cid)
        }
        
        AssertAsync {
            // Assert channel is saved to the database.
            Assert.willBeTrue(channelDTO != nil)
            // Assert query is saved to the database.
            Assert.willBeTrue(queryDTO != nil)
            // Assert query members are saved to the database.
            Assert.willBeEqual(Set(queryDTO?.members.map(\.user.id) ?? []), Set(payload.members.map(\.user.id)))
        }
    }
    
    func test_load_propagatesChannelNetworkError() {
        // Simulate `load` call and catch the error.
        var completionCalledError: Error?
        listUpdater.load(query) {
            completionCalledError = $0
        }
        
        // Assert channel endpoint is called.
        let channelEndpoint: Endpoint<ChannelPayload> = .updateChannel(query: .init(cid: query.cid))
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(channelEndpoint))
        
        // Simulate channel response with failure.
        let networkError = TestError()
        apiClient.test_simulateResponse(Result<ChannelPayload, Error>.failure(networkError))
        
        // Assert the channel network error is propogated.
        AssertAsync.willBeEqual(completionCalledError as? TestError, networkError)
    }
    
    func test_load_propagatesChannelDatabaseError() {
        // Update database to throw the error.
        let databaseError = TestError()
        database.write_errorResponse = databaseError
        
        // Simulate `load` call and catch the error.
        var completionCalledError: Error?
        listUpdater.load(query) {
            completionCalledError = $0
        }
        
        // Assert channel endpoint is called.
        let channelEndpoint: Endpoint<ChannelPayload> = .updateChannel(query: .init(cid: query.cid))
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(channelEndpoint))
        
        // Simulate channel response with  success.
        apiClient.test_simulateResponse(.success(dummyPayload(with: query.cid)))
        
        // Assert the channel database error is propogated.
        AssertAsync.willBeEqual(completionCalledError as? TestError, databaseError)
    }
    
    func test_load_propagatesMembersNetworkError() throws {
        // Save channel to the database.
        try database.createChannel(cid: query.cid)
        
        // Simulate `load` call and catch the error.
        var completionCalledError: Error?
        listUpdater.load(query) {
            completionCalledError = $0
        }
        
        // Assert members endpoint is called.
        let membersEndpoint: Endpoint<ChannelMemberListPayload> = .channelMembers(query: query)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(membersEndpoint))

        // Simulate members response with failure.
        let networkError = TestError()
        apiClient.test_simulateResponse(Result<ChannelMemberListPayload, Error>.failure(networkError))
        
        // Assert the members network call error is propogated.
        AssertAsync.willBeEqual(completionCalledError as? TestError, networkError)
    }
    
    func test_load_propagatesMembersDatabaseError() throws {
        // Save channel to the database.
        try database.createChannel(cid: query.cid)
        
        // Simulate `load` call and catch the error.
        var completionCalledError: Error?
        listUpdater.load(query) {
            completionCalledError = $0
        }
        
        // Assert members endpoint is called.
        let membersEndpoint: Endpoint<ChannelMemberListPayload> = .channelMembers(query: query)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(membersEndpoint))
        
        // Update database to throw the error.
        let databaseError = TestError()
        database.write_errorResponse = databaseError
        
        // Simulate members response with success.
        let payload = ChannelMemberListPayload(members: [
            .dummy(user: .dummy(userId: .unique)),
            .dummy(user: .dummy(userId: .unique)),
            .dummy(user: .dummy(userId: .unique))
        ])
        apiClient.test_simulateResponse(.success(payload))
        
        // Assert the database error is propogated.
        AssertAsync.willBeEqual(completionCalledError as? TestError, databaseError)
    }
    
    func test_load_resetsExistingMembers_whenFirstPageIsQueried() throws {
        // Make sure first page is being queried
        query.pagination = .init(pageSize: 10, offset: 0)
        
        // Save channel to the database.
        try database.createChannel(cid: query.cid)
        
        // Create and link a member to the query
        let memberIdThatShouldNotExists = UserId.unique
        try database.writeSynchronously { session in
            try session.saveMember(
                payload: .dummy(user: .dummy(userId: memberIdThatShouldNotExists)),
                channelId: self.query.cid,
                query: self.query
            )
        }
        
        // Simulate `load` call.
        var completionCalled = false
        listUpdater.load(query) { error in
            XCTAssertNil(error)
            completionCalled = true
        }
        
        // Assert members endpoint is called.
        let membersEndpoint: Endpoint<ChannelMemberListPayload> = .channelMembers(query: query)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(membersEndpoint))
        
        // Simulate members response.
        let payload = ChannelMemberListPayload(members: [
            .dummy(user: .dummy(userId: .unique)),
            .dummy(user: .dummy(userId: .unique)),
            .dummy(user: .dummy(userId: .unique))
        ])
        apiClient.test_simulateResponse(.success(payload))
        
        AssertAsync.willBeTrue(completionCalled)
        
        // Load query.
        var queryDTO: ChannelMemberListQueryDTO? {
            database.viewContext.channelMemberListQuery(queryHash: query.queryHash)
        }
        
        AssertAsync {
            // Assert query is saved to the database.
            Assert.willBeTrue(queryDTO != nil)
            // Assert query members are saved to the database.
            Assert.willBeEqual(Set(queryDTO?.members.map(\.user.id) ?? []), Set(payload.members.map(\.user.id)))
        }
    }
    
    func test_load_doesNotResetsExistingMembers_whenNextPageIsQueried() throws {
        // Make sure next page is being queried
        query.pagination = .init(pageSize: 10, offset: 1)
        
        // Save channel to the database.
        try database.createChannel(cid: query.cid)
        
        // Create and link a member to the query
        let existingMemberId = UserId.unique
        try database.writeSynchronously { session in
            try session.saveMember(
                payload: .dummy(user: .dummy(userId: existingMemberId)),
                channelId: self.query.cid,
                query: self.query
            )
        }
        
        // Simulate `load` call.
        var completionCalled = false
        listUpdater.load(query) { error in
            XCTAssertNil(error)
            completionCalled = true
        }
        
        // Assert members endpoint is called.
        let membersEndpoint: Endpoint<ChannelMemberListPayload> = .channelMembers(query: query)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(membersEndpoint))
        
        // Simulate members response.
        let payload = ChannelMemberListPayload(members: [
            .dummy(user: .dummy(userId: .unique)),
            .dummy(user: .dummy(userId: .unique)),
            .dummy(user: .dummy(userId: .unique))
        ])
        apiClient.test_simulateResponse(.success(payload))
        
        AssertAsync.willBeTrue(completionCalled)
        
        // Load query.
        var queryDTO: ChannelMemberListQueryDTO? {
            database.viewContext.channelMemberListQuery(queryHash: query.queryHash)
        }
        
        AssertAsync {
            // Assert query is saved to the database.
            Assert.willBeTrue(queryDTO != nil)
            // Assert query members are saved to the database.
            Assert.willBeEqual(
                Set(queryDTO?.members.map(\.user.id) ?? []),
                Set(payload.members.map(\.user.id) + [existingMemberId])
            )
        }
    }
}
