//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class CurrentUserUpdater_Tests: StressTestCase {
    typealias ExtraData = NoExtraData
    
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainerMock!
    
    var currentUserUpdater: CurrentUserUpdater<ExtraData>!
    
    // MARK: Setup
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = DatabaseContainerMock()
        
        currentUserUpdater = .init(database: database, apiClient: apiClient)
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        
        AssertAsync {
            Assert.canBeReleased(&currentUserUpdater)
            Assert.canBeReleased(&webSocketClient)
            Assert.canBeReleased(&apiClient)
            Assert.canBeReleased(&database)
        }
        
        super.tearDown()
    }
    
    // MARK: - updateUser
    
    func test_updateUser_makesCorrectAPICall() throws {
        // Simulate user already set
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Expected updated user data
        let expectedId = userPayload.id
        let expectedName = String.unique
        let expectedImageUrl = URL.unique()
        
        // Call update user
        currentUserUpdater.updateUserData(
            currentUserId: expectedId,
            name: expectedName,
            imageURL: expectedImageUrl,
            userExtraData: nil,
            completion: { error in
                XCTAssertNil(error)
            }
        )
        
        // Simulate API response
        let currentUserUpdateResponse = UserUpdateResponse(
            user: UserPayload.dummy(
                userId: userPayload.id,
                name: expectedName,
                imageUrl: expectedImageUrl
            )
        )
        apiClient.test_simulateResponse(.success(currentUserUpdateResponse))
        
        // Assert that request is made to the correct endpoint
        let expectedEndpoint: Endpoint<UserUpdateResponse<NoExtraData>> = .updateUser(
            id: expectedId,
            payload: .init(name: expectedName, imageURL: expectedImageUrl, extraData: nil)
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_updateUser_updatesCurrentUserToDatabase() throws {
        // Simulate user already set
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Expected updated user data
        let expectedId = userPayload.id
        let expectedName = String.unique
        let expectedImageUrl = URL.unique()
        
        // Call update user
        var completionCalled = false
        currentUserUpdater.updateUserData(
            currentUserId: expectedId,
            name: expectedName,
            imageURL: expectedImageUrl,
            userExtraData: nil,
            completion: { _ in
                completionCalled = true
            }
        )
        
        // Simulate API response
        let currentUserUpdateResponse = UserUpdateResponse(
            user: UserPayload.dummy(
                userId: userPayload.id,
                name: expectedName,
                imageUrl: expectedImageUrl
            )
        )
        apiClient.test_simulateResponse(.success(currentUserUpdateResponse))
        
        var currentUser: CurrentChatUser? {
            database.viewContext.currentUser()?.asModel()
        }
        
        // Check the completion is called and the current user model was updated
        AssertAsync {
            Assert.willBeTrue(completionCalled)
            Assert.willBeEqual(currentUser?.id, expectedId)
            Assert.willBeEqual(currentUser?.name, expectedName)
            Assert.willBeEqual(currentUser?.imageURL, expectedImageUrl)
        }
    }
    
    func test_updateUser_propogatesNetworkError() throws {
        // Simulate user already set
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call update user
        var completionError: Error?
        currentUserUpdater.updateUserData(
            currentUserId: userPayload.id,
            name: .unique,
            imageURL: nil,
            userExtraData: nil,
            completion: { error in
                completionError = error
            }
        )
        
        // Simulate API error
        let error = TestError()
        apiClient
            .test_simulateResponse(
                Result<UserUpdateResponse<NoExtraData>, Error>.failure(error)
            )
        apiClient
            .cleanUp()
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionError as? TestError, error)
    }
    
    func test_updateUser_whenNoDataProvided_shouldNotMakeAPICall() throws {
        // Simulate user already set
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        let error = try await {
            currentUserUpdater.updateUserData(
                currentUserId: .unique,
                name: nil,
                imageURL: nil,
                userExtraData: nil,
                completion: $0
            )
        }
        
        XCTAssertNil(error)
        XCTAssertNil(apiClient.request_endpoint)
    }
    
    func test_updateUser_propogatesDatabaseError() throws {
        // Simulate user already set
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Simulate the DB failing with `TestError`
        let testError = TestError()
        database.write_errorResponse = testError
        
        // Call update user
        var completionError: Error?
        currentUserUpdater.updateUserData(
            currentUserId: .unique,
            name: .unique,
            imageURL: nil,
            userExtraData: nil,
            completion: { error in
                completionError = error
            }
        )
        
        // Simulate API response
        let currentUserUpdateResponse = UserUpdateResponse(
            user: userPayload
        )
        apiClient.test_simulateResponse(.success(currentUserUpdateResponse))
        
        // Check returned error
        AssertAsync.willBeEqual(completionError as? TestError, testError)
    }
    
    // MARK: addDevice
    
    func test_addDevice_makesCorrectAPICall() throws {
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call addDevice
        currentUserUpdater.addDevice(token: .init(repeating: 1, count: 1), currentUserId: userPayload.id) {
            // No error should be returned
            XCTAssertNil($0)
        }
        
        // Assert that request is made to the correct endpoint
        let expectedEndpoint: Endpoint<EmptyResponse> = .addDevice(userId: userPayload.id, deviceId: "01")
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_addDevice_forwardsNetworkError() throws {
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call addDevice
        var completionCalledError: Error?
        currentUserUpdater.addDevice(token: .init(), currentUserId: .unique) {
            completionCalledError = $0
        }

        // Simulate API error
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))
        apiClient.cleanUp()
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    func test_addDevice_forwardsDatabaseError() throws {
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Simulate the DB failing with `TestError`
        let testError = TestError()
        database.write_errorResponse = testError
        
        // Call updateDevices
        var completionCalledError: Error?
        currentUserUpdater.addDevice(token: .init(repeating: 1, count: 1), currentUserId: .unique) {
            completionCalledError = $0
        }
        
        // Simulate successful API response
        apiClient.test_simulateResponse(.success(EmptyResponse()))
        
        // Check returned error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    func test_addDevice_successfulResponse_isSavedToDB() throws {
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call updateDevices
        currentUserUpdater.addDevice(token: .init(repeating: 1, count: 1), currentUserId: .unique) {
            // No error should be returned
            XCTAssertNil($0)
        }
        
        // Simulate API response with devices data
        apiClient.test_simulateResponse(.success(EmptyResponse()))
        
        // Assert data is stored in the DB
        var currentUser: CurrentChatUser? {
            database.viewContext.currentUser()?.asModel()
        }
        
        AssertAsync {
            Assert.willBeEqual(currentUser?.devices.count, 2)
        }
    }
    
    // MARK: removeDevice
    
    func test_removeDevice_makesCorrectAPICall() throws {
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call removeDevice
        currentUserUpdater.removeDevice(id: "01", currentUserId: userPayload.id) {
            // No error should be returned
            XCTAssertNil($0)
        }
        
        // Assert that request is made to the correct endpoint
        let expectedEndpoint: Endpoint<EmptyResponse> = .removeDevice(userId: userPayload.id, deviceId: "01")
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_removeDevice_forwardsNetworkError() throws {
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call removeDevice
        var completionCalledError: Error?
        currentUserUpdater.removeDevice(id: "", currentUserId: .unique) {
            completionCalledError = $0
        }
        
        // Simulate API error
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))
        apiClient.cleanUp()
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    func test_removeDevice_forwardsDatabaseError() throws {
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        let deviceId = userPayload.devices.first!.id
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Simulate the DB failing with `TestError`
        let testError = TestError()
        database.write_errorResponse = testError
        
        // Call updateDevices
        var completionCalledError: Error?
        currentUserUpdater.removeDevice(id: deviceId, currentUserId: .unique) {
            completionCalledError = $0
        }
        
        // Simulate successful API response
        apiClient.test_simulateResponse(.success(EmptyResponse()))
        
        // Check returned error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    func test_removeDevice_successfulResponse_isSavedToDB() throws {
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        let deviceId = userPayload.devices.first!.id
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call updateDevices
        currentUserUpdater.removeDevice(id: deviceId, currentUserId: .unique) {
            // No error should be returned
            XCTAssertNil($0)
        }
        
        // Simulate API response with devices data
        apiClient.test_simulateResponse(.success(EmptyResponse()))
        
        // Assert data is stored in the DB
        var currentUser: CurrentChatUser? {
            database.viewContext.currentUser()?.asModel()
        }
        
        AssertAsync {
            Assert.willBeEqual(currentUser?.devices.count, 0)
        }
    }
    
    // MARK: updateDevices
    
    func test_updateDevices_makesCorrectAPICall() throws {
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call updateDevices
        currentUserUpdater.updateDevices(currentUserId: userPayload.id) {
            // No error should be returned
            XCTAssertNil($0)
        }
        
        // Assert that request is made to the correct endpoint
        let expectedEndpoint: Endpoint<DeviceListPayload> = .devices(userId: userPayload.id)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_updateDevices_forwardsNetworkError() throws {
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call updateDevices
        var completionCalledError: Error?
        currentUserUpdater.updateDevices(currentUserId: .unique) {
            completionCalledError = $0
        }
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakcurrentUserUpdater = currentUserUpdater
        
        // (Try to) deallocate the currentUserUpdater
        // by not keeping any references to it
        currentUserUpdater = nil
        
        // Simulate API error
        let error = TestError()
        apiClient.test_simulateResponse(Result<DeviceListPayload, Error>.failure(error))
        apiClient.cleanUp()
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
        // `weakcurrentUserUpdater` should be deallocated too
        AssertAsync.canBeReleased(&weakcurrentUserUpdater)
    }
    
    func test_updateDevices_forwardsDatabaseError() throws {
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Simulate the DB failing with `TestError`
        let testError = TestError()
        database.write_errorResponse = testError
        
        // Call updateDevices
        var completionCalledError: Error?
        currentUserUpdater.updateDevices(currentUserId: .unique) {
            completionCalledError = $0
        }
        
        // Simulate successful API response
        apiClient.test_simulateResponse(.success(DeviceListPayload.dummy))
        
        // Check returned error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    func test_updateDevices_successfulResponse_isSavedToDB() throws {
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Save previous device to the db
        try database.writeSynchronously {
            try $0.saveCurrentUserDevices([.dummy])
        }
        
        // Call updateDevices
        currentUserUpdater.updateDevices(currentUserId: .unique) {
            // No error should be returned
            XCTAssertNil($0)
        }
        
        // Simulate API response with devices data
        let dummyDevices = DeviceListPayload.dummy
        apiClient.test_simulateResponse(.success(dummyDevices))
        
        // Assert data is stored in the DB
        var currentUser: CurrentChatUser? {
            database.viewContext.currentUser()?.asModel()
        }
        
        // Previous devices should not be cleared
        AssertAsync {
            Assert.willBeEqual(currentUser?.devices.count, 2)
            Assert.willBeEqual(currentUser?.devices.last?.id, dummyDevices.devices.last?.id)
        }
    }
}
