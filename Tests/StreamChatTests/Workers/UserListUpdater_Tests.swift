//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserListUpdater_Tests: XCTestCase {
    var webSocketClient: WebSocketClient_Mock!
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer!
    
    var listUpdater: UserListUpdater!
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClient_Mock()
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        
        listUpdater = UserListUpdater(database: database, apiClient: apiClient)
    }
    
    override func tearDown() {
        apiClient.cleanUp()

        AssertAsync {
            Assert.canBeReleased(&apiClient)
            Assert.canBeReleased(&listUpdater)
            Assert.canBeReleased(&database)
            Assert.canBeReleased(&webSocketClient)
        }

        apiClient = nil
        listUpdater = nil
        database = nil
        webSocketClient = nil

        super.tearDown()
    }
    
    // MARK: - Update
    
    func test_update_makesCorrectAPICall() {
        // Simulate `update` call
        let query = UserListQuery(filter: .equal(.id, to: "Luke"))
        listUpdater.update(userListQuery: query)
        
        let referenceEndpoint: Endpoint<UserListPayload> = .users(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_update_successfullReponseData_areSavedToDB() {
        // Simulate `update` call
        let query = UserListQuery(filter: .equal(.id, to: "Luke"))
        var completionCalled = false
        listUpdater.update(userListQuery: query, completion: { error in
            XCTAssertNil(error)
            completionCalled = true
        })
        
        // Simualte API response with user data
        let dummyUser1 = dummyUser
        let id = dummyUser1.id
        let payload = UserListPayload(users: [dummyUser1])
        apiClient.test_simulateResponse(.success(payload))
        
        // Assert the data is stored in the DB
        var user: ChatUser? { try self.user(with: id) }

        AssertAsync {
            Assert.willBeTrue((try? user) != nil)
            Assert.willBeTrue(completionCalled)
        }
    }
    
    func test_update_errorResponse_isPropagatedToCompletion() {
        // Simulate `update` call
        let query = UserListQuery(filter: .equal(.id, to: "Luke"))
        var completionCalledError: Error?
        listUpdater.update(userListQuery: query, completion: { completionCalledError = $0 })
        
        // Simualte API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<UserListPayload, Error>.failure(error))
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    func test_update_shouldNotHaveMemoryLeaks() {
        let exp = expectation(description: "should clean the listUpdater")

        weak var weakListUpdater: UserListUpdater?

        weakListUpdater = listUpdater
        let query = UserListQuery(filter: .equal(.id, to: "Luke"))
        listUpdater.update(userListQuery: query, completion: { [weak self] _ in
            self?.listUpdater = nil
            exp.fulfill()
        })

        // Simualte API response with user data
        let dummyUser1 = dummyUser
        let payload = UserListPayload(users: [dummyUser1])
        apiClient.test_simulateResponse(.success(payload))

        wait(for: [exp], timeout: 0.5)

        XCTAssertNil(weakListUpdater)
    }
    
    func test_mergePolicy_takesAffect() throws {
        // Simulate `update` call
        let query = UserListQuery(filter: .equal(.id, to: "Luke"))
        listUpdater.update(userListQuery: query)
        
        // Simulate API response with user data
        let userId = UserId.unique
        let payload = UserListPayload(users: [.dummy(userId: userId)])
        apiClient.test_simulateResponse(.success(payload))

        // Assert user is inserted into DB
        AssertAsync.willBeTrue((try? self.user(with: userId)) != nil)
        let user = try self.user(with: userId)
        
        // Simulate consequent `update` call with new users and `.merge` policy
        // We don't pass the `policy` argument since we expect it's `merge` by default
        listUpdater.update(userListQuery: query)
        
        // Simulate API response with user data
        let newUserId = UserId.unique
        let newPayload = UserListPayload(users: [.dummy(userId: newUserId)])
        apiClient.test_simulateResponse(.success(newPayload))
        
        // Assert new user is inserted into DB
        AssertAsync.willBeTrue((try? self.user(with: newUserId)) != nil)
        let newUser = try self.user(with: newUserId)

        let userIds = [user!, newUser!].map(\.id)

        // Assert both users are linked to the same query now
        try database.writeSynchronously { session in
            do {
                let dto = try session.saveQuery(query: query)
                XCTAssertEqual(dto!.users.count, 2)
                XCTAssertEqual(
                    dto!.users.map(\.id).sorted(),
                    userIds.sorted()
                )
            } catch {
                XCTFail("Error trying to get query: \(error)")
            }
        }
    }
    
    func test_removePolicy_takesAffect() throws {
        // Create query
        let query = UserListQuery(filter: .equal(.id, to: "Luke"))
        // Simulate `update` call
        // This call doesn't need `policy` argument specified since
        // it's the first call for this query, hence there's no data to `replace` or `merge` to
        listUpdater.update(userListQuery: query)
        
        // Simulate API response with user data
        let userId = UserId.unique
        let payload = UserListPayload(users: [.dummy(userId: userId)])
        apiClient.test_simulateResponse(.success(payload))
        
        // Assert user is inserted into DB
        AssertAsync.willBeTrue((try? self.user(with: userId)) != nil)
        let user = try self.user(with: userId)

        // Assert user is inserted into DB
        AssertAsync.willBeTrue(user != nil)
        
        // Simulate consequent `update` call with new users and `.replace` policy
        listUpdater.update(userListQuery: query, policy: .replace)
        
        // Simulate API response with user data
        let newUserId = UserId.unique
        let newPayload = UserListPayload(users: [.dummy(userId: newUserId)])
        apiClient.test_simulateResponse(.success(newPayload))
        
        // Assert new user is inserted into DB
        AssertAsync.willBeTrue((try? self.user(with: newUserId)) != nil)
        let newUser = try self.user(with: newUserId)

        // Assert first user is not linked to the query anymore
        var queryDTO: UserListQueryDTO? {
            database.viewContext.userListQuery(filterHash: query.filter!.filterHash)
        }
        
        // Assert only 1 user is linked to query
        XCTAssertEqual(queryDTO!.users.count, 1)
        // Assert new user is linked to query
        XCTAssertEqual(queryDTO!.users.map(\.id), [newUser!].map(\.id))
    }
    
    func test_updateCompletion_calledAfterDBWriteCompletes() {
        let dummyUserId = UserId.unique
        
        // Simulate `update` call
        let query = UserListQuery(filter: .equal(.id, to: "Luke"))
        var completionCalled = false
        listUpdater.update(userListQuery: query, completion: { _ in
            // At this point, DB write should have completed
            
            // Assert the data is stored in the DB
            // We call this block in `main` queue since we need to access `viewContext`
            DispatchQueue.main.sync {
                let user: ChatUser? = try? self.user(with: dummyUserId)
            
                XCTAssert(user != nil)
                
                completionCalled = true
            }
        })
        
        // Simulate API response with user data
        let user = dummyUser(id: dummyUserId)
        let payload = UserListPayload(users: [user])
        apiClient.test_simulateResponse(.success(payload))
        
        AssertAsync.willBeTrue(completionCalled)
    }
    
    // MARK: - Fetch
    
    func test_fetch_makesCorrectAPICall() {
        // Simulate `fetch` call
        let query = UserListQuery(filter: .equal(.id, to: "Luke"))
        listUpdater.fetch(userListQuery: query, completion: { _ in })
        
        let referenceEndpoint: Endpoint<UserListPayload> = .users(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_fetch_whenSuccess_payloadIsPropagatedToCompletion() {
        // Simulate `fetch` call
        let query = UserListQuery(filter: .equal(.id, to: "Luke"))
        var userListPayload: UserListPayload?
        listUpdater.fetch(userListQuery: query, completion: { result in
            XCTAssertNil(result.error)
            userListPayload = try? result.get()
        })
        
        // Simualte API response with user data
        let payload = UserListPayload(users: [dummyUser])
        apiClient.test_simulateResponse(.success(payload))
        
        AssertAsync.willBeEqual(
            Set(payload.users.map(\.id)),
            Set(userListPayload?.users.map(\.id) ?? [])
        )
    }
    
    func test_fetch_whenFailure_errorIsPropagatedToCompletion() {
        // Simulate `fetch` call
        let query = UserListQuery(filter: .equal(.id, to: "Luke"))
        var completionCalledError: Error?
        listUpdater.fetch(userListQuery: query, completion: { completionCalledError = $0.error })
        
        // Simualte API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<UserListPayload, Error>.failure(error))
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    func test_fetch_doesNotRetainSelf() {
        // Simulate `fetch` call
        let query = UserListQuery(filter: .equal(.id, to: "Luke"))
        listUpdater.fetch(userListQuery: query, completion: { _ in })
        
        // Assert updater can be released
        AssertAsync.canBeReleased(&listUpdater)
    }
}

private extension UserListUpdater_Tests {
    func user(with id: UserId) throws -> ChatUser? {
        try database.viewContext.user(id: id)?.asModel()
    }
}
