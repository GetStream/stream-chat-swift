//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class CurrentUserUpdater_Tests: XCTestCase {
    var webSocketClient: WebSocketClient_Mock!
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!
    
    var currentUserUpdater: CurrentUserUpdater!
    
    // MARK: Setup
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClient_Mock()
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        
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

        currentUserUpdater = nil
        webSocketClient = nil
        apiClient = nil
        database = nil

        super.tearDown()
    }
    
    // MARK: - updateUser
    
    func test_updateUser_makesCorrectAPICall() throws {
        // Simulate user already set
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
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
        let expectedEndpoint: Endpoint<UserUpdateResponse> = .updateUser(
            id: expectedId,
            payload: .init(name: expectedName, imageURL: expectedImageUrl)
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_updateUser_updatesCurrentUserToDatabase() throws {
        // Simulate user already set
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
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
            database.viewContext.currentUser?.asModel()
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
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call update user
        var completionError: Error?
        currentUserUpdater.updateUserData(
            currentUserId: userPayload.id,
            name: .unique,
            imageURL: nil,
            completion: { error in
                completionError = error
            }
        )
        
        // Simulate API error
        let error = TestError()
        apiClient
            .test_simulateResponse(
                Result<UserUpdateResponse, Error>.failure(error)
            )
        apiClient
            .cleanUp()
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionError as? TestError, error)
    }
    
    func test_updateUser_whenNoDataProvided_shouldNotMakeAPICall() throws {
        // Simulate user already set
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        let error = try waitFor {
            currentUserUpdater.updateUserData(
                currentUserId: .unique,
                name: nil,
                imageURL: nil,
                completion: $0
            )
        }
        
        XCTAssertNil(error)
        XCTAssertNil(apiClient.request_endpoint)
    }
    
    func test_updateUser_propogatesDatabaseError() throws {
        // Simulate user already set
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
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
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call addDevice
        currentUserUpdater.addDevice(
            token: .init(repeating: 1, count: 1),
            currentUserId: userPayload.id,
            pushProvider: .apn
        ) {
            // No error should be returned
            XCTAssertNil($0)
        }
        
        // Assert that request is made to the correct endpoint
        let expectedEndpoint: Endpoint<EmptyResponse> = .addDevice(
            userId: userPayload.id,
            deviceId: "01",
            pushProvider: .apn
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_addDevice_forwardsNetworkError() throws {
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call addDevice
        var completionCalledError: Error?
        currentUserUpdater.addDevice(token: .init(), currentUserId: .unique, pushProvider: .apn) {
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
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Simulate the DB failing with `TestError`
        let testError = TestError()
        database.write_errorResponse = testError
        
        // Call fetchDevices
        var completionCalledError: Error?
        currentUserUpdater.addDevice(
            token: .init(repeating: 1, count: 1),
            currentUserId: .unique,
            pushProvider: .apn
        ) {
            completionCalledError = $0
        }
        
        // Simulate successful API response
        apiClient.test_simulateResponse(.success(EmptyResponse()))
        
        // Check returned error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    func test_addDevice_successfulResponse_isSavedToDB() throws {
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user, devices: [.dummy])
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        // Assert data is stored in the DB
        var currentUser: CurrentChatUser? {
            database.viewContext.currentUser?.asModel()
        }

        // Assert the initial values, where we have
        // 1 device saved and no currentDevice set
        assert(currentUser?.devices.count == 1)
        assert(currentUser?.currentDevice == nil)

        // Call addDevice
        currentUserUpdater.addDevice(
            token: .init(repeating: 1, count: 1),
            currentUserId: .unique,
            pushProvider: .apn
        ) {
            // No error should be returned
            XCTAssertNil($0)
        }
        
        // Simulate API response with devices data
        apiClient.test_simulateResponse(.success(EmptyResponse()))
        
        AssertAsync {
            // Assert the new device is added to devices
            Assert.willBeEqual(currentUser?.devices.count, 2)
            // Assert that currentDevice is set
            Assert.willBeTrue(currentUser?.currentDevice != nil)
        }
    }
    
    // MARK: removeDevice
    
    func test_removeDevice_makesCorrectAPICall() throws {
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        
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
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        
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
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user, devices: [.dummy])
        let deviceId = userPayload.devices.first!.id
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Simulate the DB failing with `TestError`
        let testError = TestError()
        database.write_errorResponse = testError
        
        // Call fetchDevices
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
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user, devices: [.dummy])
        let deviceId = userPayload.devices.first!.id
        
        // Save user to the db
        try database.writeSynchronously {
            let dto = try $0.saveCurrentUser(payload: userPayload)
            dto.currentDevice = dto.devices.first
        }
        
        // Call fetchDevices
        currentUserUpdater.removeDevice(id: deviceId, currentUserId: .unique) {
            // No error should be returned
            XCTAssertNil($0)
        }
        
        // Simulate API response with devices data
        apiClient.test_simulateResponse(.success(EmptyResponse()))
        
        // Assert data is stored in the DB
        var currentUser: CurrentChatUser? {
            database.viewContext.currentUser?.asModel()
        }
        
        AssertAsync {
            Assert.willBeEqual(currentUser?.devices.count, 0)
            Assert.willBeEqual(currentUser?.currentDevice, nil)
        }
    }
    
    // MARK: fetchDevices
    
    func test_fetchDevices_makesCorrectAPICall() throws {
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call updateDevices
        currentUserUpdater.fetchDevices(currentUserId: userPayload.id) {
            // No error should be returned
            XCTAssertNil($0)
        }
        
        // Assert that request is made to the correct endpoint
        let expectedEndpoint: Endpoint<DeviceListPayload> = .devices(userId: userPayload.id)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_fetchDevices_forwardsNetworkError() throws {
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call updateDevices
        var completionCalledError: Error?
        currentUserUpdater.fetchDevices(currentUserId: .unique) {
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
    
    func test_fetchDevices_forwardsDatabaseError() throws {
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Simulate the DB failing with `TestError`
        let testError = TestError()
        database.write_errorResponse = testError
        
        // Call updateDevices
        var completionCalledError: Error?
        currentUserUpdater.fetchDevices(currentUserId: .unique) {
            completionCalledError = $0
        }
        
        // Simulate successful API response
        apiClient.test_simulateResponse(.success(DeviceListPayload.dummy))
        
        // Check returned error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    func test_fetchDevices_successfulResponse_isSavedToDB() throws {
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        // Assert data is stored in the DB
        var currentUser: CurrentChatUser? {
            database.viewContext.currentUser?.asModel()
        }

        // Make sure no devices are stored in the DB
        assert(currentUser?.devices.isEmpty == true)

        // Save previous device to the db
        try database.writeSynchronously {
            // Simulate 4 devices exist in the DB
            try $0.saveCurrentUserDevices([.dummy, .dummy, .dummy, .dummy])
        }

        // Call updateDevices
        var callbackCalled = false
        currentUserUpdater.fetchDevices(currentUserId: .unique) {
            // No error should be returned
            XCTAssertNil($0)
            callbackCalled = true
        }
        
        // Simulate API response with devices data
        let dummyDevices = DeviceListPayload.dummy
        assert(dummyDevices.devices.isEmpty == false)
        apiClient.test_simulateResponse(.success(dummyDevices))

        // Previous devices should not be cleared
        AssertAsync {
            Assert.willBeEqual(
                currentUser?.devices.map(\.id).sorted(),
                dummyDevices.devices.map(\.id).sorted()
            )
            Assert.willBeTrue(callbackCalled)
        }
    }
    
    // MARK: - Mark all read
    
    func test_markAllRead_makesCorrectAPICall() {
        
        // GIVEN
        
        XCTAssertNil(apiClient.request_endpoint)
        
        // WHEN
        
        currentUserUpdater.markAllRead()
        
        // THEN
        
        let referenceEndpoint = Endpoint<EmptyResponse>.markAllRead()
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_markAllRead_successfulResponse_isPropagatedToCompletion() {
        
        // GIVEN
        
        var completionCalled = false
        XCTAssertFalse(completionCalled)
        
        // WHEN
        
        currentUserUpdater.markAllRead { error in
            XCTAssertNil(error)
            completionCalled = true
        }
        
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
        
        // THEN
        
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_markAllRead_errorResponse_isPropagatedToCompletion() {

        // GIVEN
        
        var completionCalledError: Error?
        let error = TestError()
        XCTAssertNil(completionCalledError)
        
        // WHEN
        
        currentUserUpdater.markAllRead { completionCalledError = $0 }
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))
        
        // THEN
        
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
}
