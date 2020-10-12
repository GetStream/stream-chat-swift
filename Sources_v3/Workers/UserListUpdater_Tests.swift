//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class UserListUpdater_Tests: StressTestCase {
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainer!
    
    var listUpdater: UserListUpdater<DefaultExtraData.User>!
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = try! DatabaseContainer(kind: .inMemory)
        
        listUpdater = UserListUpdater(database: database, webSocketClient: webSocketClient, apiClient: apiClient)
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        
        AssertAsync.canBeReleased(&listUpdater)
        
        super.tearDown()
    }
    
    // MARK: - Update
    
    func test_update_makesCorrectAPICall() {
        // Simulate `update` call
        let query = UserListQuery<DefaultExtraData.User>(filter: .equal(.id, to: "Luke"))
        listUpdater.update(userListQuery: query)
        
        let referenceEndpoint: Endpoint<UserListPayload<DefaultExtraData.User>> = .users(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_update_successfullReponseData_areSavedToDB() {
        // Simulate `update` call
        let query = UserListQuery<DefaultExtraData.User>(filter: .equal(.id, to: "Luke"))
        var completionCalled = false
        listUpdater.update(userListQuery: query, completion: { error in
            XCTAssertNil(error)
            completionCalled = true
        })
        
        // Simualte API response with user data
        let dummyUser1 = dummyUser
        let id = dummyUser1.id
        let payload = UserListPayload<DefaultExtraData.User>(users: [dummyUser1])
        apiClient.test_simulateResponse(.success(payload))
        
        // Assert the data is stored in the DB
        var user: ChatUser? {
            database.viewContext.user(id: id)?.asModel()
        }
        
        AssertAsync {
            Assert.willBeTrue(user != nil)
            Assert.willBeTrue(completionCalled)
        }
    }
    
    func test_update_errorResponse_isPropagatedToCompletion() {
        // Simulate `update` call
        let query = UserListQuery<DefaultExtraData.User>(filter: .equal(.id, to: "Luke"))
        var completionCalledError: Error?
        listUpdater.update(userListQuery: query, completion: { completionCalledError = $0 })
        
        // Simualte API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<UserListPayload<DefaultExtraData.User>, Error>.failure(error))
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
}
