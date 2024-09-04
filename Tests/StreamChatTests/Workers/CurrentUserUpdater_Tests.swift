//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        let expectedRole = UserRole.guest

        // Call update user
        currentUserUpdater.updateUserData(
            currentUserId: expectedId,
            name: expectedName,
            imageURL: expectedImageUrl,
            privacySettings: .init(
                typingIndicators: .init(enabled: true),
                readReceipts: .init(enabled: true)
            ),
            role: expectedRole,
            userExtraData: nil,
            completion: { error in
                XCTAssertNil(error)
            }
        )

        // Simulate API response
        let currentUserUpdateResponse = CurrentUserUpdateResponse(
            user: CurrentUserPayload.dummy(
                userId: userPayload.id,
                name: expectedName,
                imageUrl: expectedImageUrl,
                role: expectedRole,
                privacySettings: .init(
                    typingIndicators: .init(enabled: true),
                    readReceipts: .init(enabled: true)
                )
            )
        )
        apiClient.test_simulateResponse(.success(currentUserUpdateResponse))

        // Assert that request is made to the correct endpoint
        let expectedEndpoint: Endpoint<CurrentUserUpdateResponse> = .updateUser(
            id: expectedId,
            payload: .init(
                name: expectedName,
                imageURL: expectedImageUrl,
                privacySettings: .init(
                    typingIndicators: .init(enabled: true),
                    readReceipts: .init(enabled: true)
                ),
                role: expectedRole,
                extraData: [:]
            ),
            unset: []
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_updateUser_makesCorrectAPICall_whenOnlyUnsetProperties() throws {
        // Simulate user already set
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        currentUserUpdater.updateUserData(
            currentUserId: userPayload.id,
            name: nil,
            imageURL: nil,
            privacySettings: nil,
            role: nil,
            userExtraData: nil,
            unset: ["image"],
            completion: { _ in }
        )
        
        // Assert that request is made to the correct endpoint
        let expectedEndpoint: Endpoint<CurrentUserUpdateResponse> = .updateUser(
            id: userPayload.id,
            payload: .init(
                name: nil,
                imageURL: nil,
                privacySettings: nil,
                role: nil,
                extraData: nil
            ),
            unset: ["image"]
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
        let expectedRole = UserRole.anonymous

        // Call update user
        var completionCalled = false
        currentUserUpdater.updateUserData(
            currentUserId: expectedId,
            name: expectedName,
            imageURL: expectedImageUrl,
            privacySettings: .init(
                typingIndicators: .init(enabled: false),
                readReceipts: .init(enabled: false)
            ),
            role: expectedRole,
            userExtraData: nil,
            completion: { _ in
                completionCalled = true
            }
        )

        // Simulate API response
        let currentUserUpdateResponse = CurrentUserUpdateResponse(
            user: CurrentUserPayload.dummy(
                userId: userPayload.id,
                name: expectedName,
                imageUrl: expectedImageUrl,
                role: expectedRole,
                privacySettings: .init(
                    typingIndicators: .init(enabled: false),
                    readReceipts: .init(enabled: false)
                )
            )
        )
        apiClient.test_simulateResponse(.success(currentUserUpdateResponse))

        var currentUser: CurrentChatUser? {
            try? database.viewContext.currentUser?.asModel()
        }

        // Check the completion is called and the current user model was updated
        AssertAsync {
            Assert.willBeTrue(completionCalled)
            Assert.willBeEqual(currentUser?.id, expectedId)
            Assert.willBeEqual(currentUser?.name, expectedName)
            Assert.willBeEqual(currentUser?.imageURL, expectedImageUrl)
            Assert.willBeEqual(currentUser?.privacySettings.readReceipts?.enabled, false)
            Assert.willBeEqual(currentUser?.privacySettings.typingIndicators?.enabled, false)
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
            privacySettings: nil,
            role: nil,
            userExtraData: [:],
            completion: { error in
                completionError = error
            }
        )

        // Simulate API error
        let error = TestError()
        apiClient
            .test_simulateResponse(
                Result<CurrentUserUpdateResponse, Error>.failure(error)
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
                privacySettings: nil,
                role: nil,
                userExtraData: nil,
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
            privacySettings: nil,
            role: nil,
            userExtraData: nil,
            completion: { error in
                completionError = error
            }
        )

        // Simulate API response
        let currentUserUpdateResponse = CurrentUserUpdateResponse(
            user: userPayload
        )
        apiClient.test_simulateResponse(.success(currentUserUpdateResponse))

        // Check returned error
        AssertAsync.willBeEqual(completionError as? TestError, testError)
    }

    // MARK: addDevice

    func test_addDevice_makesCorrectAPICall() throws {
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        let deviceId = "test"
        let pushProvider = PushProvider.apn
        let providerName = "APN Configuration"

        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        // Mock successful API response
        apiClient.test_mockResponseResult(.success(EmptyResponse()))

        // Call addDevice
        currentUserUpdater.addDevice(
            deviceId: deviceId,
            pushProvider: pushProvider,
            providerName: providerName,
            currentUserId: userPayload.id
        ) {
            // No error should be returned
            XCTAssertNil($0)
        }

        // Assert that request is made to the correct endpoint
        let expectedEndpoint: Endpoint<EmptyResponse> = .addDevice(
            userId: userPayload.id,
            deviceId: deviceId,
            pushProvider: pushProvider,
            providerName: providerName
        )

        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_addDevice_forwardsNetworkError() throws {
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)

        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        // Mock failure API response
        let error = TestError()
        apiClient.test_mockResponseResult(Result<EmptyResponse, Error>.failure(error))

        // Call addDevice
        var completionCalledError: Error?
        currentUserUpdater.addDevice(
            deviceId: "test",
            pushProvider: .apn,
            currentUserId: .unique
        ) {
            completionCalledError = $0
        }

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    func test_addDevice_successfulResponse_isSavedToDB() throws {
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user, devices: [.dummy])

        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        // Assert data is stored in the DB
        var currentUser: CurrentChatUser? {
            try? database.viewContext.currentUser?.asModel()
        }

        // Assert the initial values, where we have
        // 1 device saved and no currentDevice set
        assert(currentUser?.devices.count == 1)
        assert(currentUser?.currentDevice == nil)

        // Mock successful API response
        apiClient.test_mockResponseResult(.success(EmptyResponse()))

        // Call addDevice
        currentUserUpdater.addDevice(
            deviceId: "test",
            pushProvider: .apn,
            currentUserId: .unique
        ) {
            // No error should be returned
            XCTAssertNil($0)
        }

        AssertAsync {
            // Assert the new device is added to devices
            Assert.willBeEqual(currentUser?.devices.count, 2)
            // Assert that currentDevice is set
            Assert.willBeTrue(currentUser?.currentDevice != nil)
        }
    }

    func test_addDevice_whenCallingFromBackgroundThread_doesNotCrash() throws {
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        let deviceId = "test"
        let pushProvider = PushProvider.apn
        let providerName = "APN Configuration"

        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        // Mock successful API response
        apiClient.test_mockResponseResult(.success(EmptyResponse()))

        let exp = expectation(description: "should complete addDevice call")

        DispatchQueue.global().async {
            self.currentUserUpdater.addDevice(
                deviceId: deviceId,
                pushProvider: pushProvider,
                providerName: providerName,
                currentUserId: userPayload.id
            ) { _ in
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: defaultTimeout)
    }

    // MARK: removeDevice

    func test_removeDevice_makesCorrectAPICall() throws {
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user)

        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        apiClient.test_mockResponseResult(.success(EmptyResponse()))
        let expectation = XCTestExpectation()
        
        // Call removeDevice
        currentUserUpdater.removeDevice(id: "01", currentUserId: userPayload.id) {
            // No error should be returned
            XCTAssertNil($0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: defaultTimeout)
        
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
        
        apiClient.test_mockResponseResult(.success(EmptyResponse()))
        let expectation = XCTestExpectation()

        // Call removeDevice
        var completionCalledError: Error?
        currentUserUpdater.removeDevice(id: "", currentUserId: .unique) {
            completionCalledError = $0
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: defaultTimeout)
        
        // Simulate API error
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))
        apiClient.cleanUp()

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
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
            try? database.viewContext.currentUser?.asModel()
        }

        AssertAsync {
            Assert.willBeEqual(currentUser?.devices.count, 0)
            Assert.willBeEqual(currentUser?.currentDevice, nil)
        }
    }

    // MARK: fetchDevices

    func test_fetchDevices_makesCorrectAPICall() throws {
        let payloads: [DevicePayload] = [.dummy, .dummy]
        let expectedDevices = payloads.map { Device(id: $0.id, createdAt: $0.createdAt) }
        let userPayload: CurrentUserPayload = .dummy(userId: .unique, role: .user, devices: payloads)

        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        // Call updateDevices
        currentUserUpdater.fetchDevices(currentUserId: userPayload.id) {
            // No error should be returned
            XCTAssertNil($0.error)
            XCTAssertEqual($0, success: expectedDevices)
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
            completionCalledError = $0.error
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
            completionCalledError = $0.error
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
            try? database.viewContext.currentUser?.asModel()
        }

        // Make sure no devices are stored in the DB
        assert(currentUser?.devices.isEmpty == true)

        // Save previous device to the db
        try database.writeSynchronously {
            // Simulate 4 devices exist in the DB
            try $0.saveCurrentUserDevices([.dummy, .dummy, .dummy, .dummy])
        }
        
        let dummyDevices = DeviceListPayload.dummy
        let apiDevices = dummyDevices.devices.map { Device(id: $0.id, createdAt: $0.createdAt) }

        // Call updateDevices
        var callbackCalled = false
        currentUserUpdater.fetchDevices(currentUserId: .unique) { result in
            XCTAssertEqual(result, success: apiDevices)
            callbackCalled = true
        }

        // Simulate API response with devices data
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
        let referenceEndpoint = Endpoint<EmptyResponse>.markAllRead()

        // WHEN
        currentUserUpdater.markAllRead()

        // THEN
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_markAllRead_successfulResponse_isPropagatedToCompletion() {
        // GIVEN
        var completionCalled = false

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

        // WHEN
        currentUserUpdater.markAllRead { completionCalledError = $0 }
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // THEN
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    // MARK: - Delete Local Downloads
    
    func test_deleteAllLocalAttachmentDownloads_success() throws {
        let storedFileCount: () -> Int = {
            let paths = try? FileManager.default.subpathsOfDirectory(atPath: URL.streamAttachmentDownloadsDirectory.path)
            return paths?.count ?? 0
        }
        if FileManager.default.fileExists(atPath: URL.streamAttachmentDownloadsDirectory.path) {
            try FileManager.default.removeItem(at: .streamAttachmentDownloadsDirectory)
        }
        
        let attachmentIds = try (0..<5).map { _ in try setUpDownloadedAttachment(with: .mockFile) }
        XCTAssertEqual(5, storedFileCount())
        
        let error = try waitFor { currentUserUpdater.deleteAllLocalAttachmentDownloads(completion: $0) }
        XCTAssertNil(error)
        XCTAssertEqual(0, storedFileCount())
        
        try database.readSynchronously { session in
            for attachmentId in attachmentIds {
                guard let dto = session.attachment(id: attachmentId) else {
                    throw ClientError.AttachmentDoesNotExist(id: attachmentId)
                }
                XCTAssertEqual(nil, dto.localState)
                XCTAssertEqual(nil, dto.localRelativePath)
                XCTAssertEqual(nil, dto.localURL)
            }
        }
    }
    
    // MARK: -
    
    private func setUpDownloadedAttachment(with payload: AnyAttachmentPayload, messageId: MessageId = .unique, cid: ChannelId = .unique) throws -> AttachmentId {
        let attachmentId: AttachmentId = .init(cid: cid, messageId: messageId, index: 0)
        try FileManager.default.createDirectory(at: .streamAttachmentDownloadsDirectory, withIntermediateDirectories: true)
        try database.createChannel(cid: cid, withMessages: false)
        try database.createMessage(id: messageId, cid: cid)
        try database.writeSynchronously { session in
            let dto = try session.createNewAttachment(attachment: payload, id: attachmentId)
            let localRelativePath = messageId + "-file.txt"
            dto.localDownloadState = .downloaded
            dto.localRelativePath = localRelativePath
            let localFileURL = URL.streamAttachmentLocalStorageURL(forRelativePath: localRelativePath)
            try FileManager.default.createDirectory(at: localFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try UUID().uuidString.write(to: localFileURL, atomically: false, encoding: .utf8)
            XCTAssertTrue(FileManager.default.fileExists(atPath: localFileURL.path))
        }
        return attachmentId
    }
}
