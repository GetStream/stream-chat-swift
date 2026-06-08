//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        let userPayload: OwnUserResponse = .dummy(userId: .unique, role: .user)
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        // Expected updated user data
        let expectedId = userPayload.id
        let expectedName = String.unique
        let expectedImageUrl = URL.unique()
        let expectedRole = UserRole.guest
        let expectedNote = String.unique

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
            teamsRole: ["ios": "guest"],
            userExtraData: ["secret_note": .string(expectedNote)],
            unset: ["image"],
            completion: { error in
                XCTAssertNil(error)
            }
        )

        // Simulate API response
        let currentUserUpdateResponse = UpdateUsersResponse.dummy(
            user: OwnUserResponse.dummy(
                userId: userPayload.id,
                name: expectedName,
                imageUrl: expectedImageUrl,
                role: expectedRole,
                teamsRole: ["ios": "guest"],
                privacySettings: .init(
                    typingIndicators: .init(enabled: true),
                    readReceipts: .init(enabled: true)
                )
            )
        )
        apiClient.test_simulateResponse(.success(currentUserUpdateResponse))

        // Assert that request is made to the correct endpoint
        let expectedSet: [String: RawJSON] = [
            "name": .string(expectedName),
            "image": .string(expectedImageUrl.absoluteString),
            "privacy_settings": UserPrivacySettings(
                typingIndicators: .init(enabled: true),
                readReceipts: .init(enabled: true)
            ).asPrivacySettingsResponse.rawJSON!,
            "role": .string(expectedRole.rawValue),
            "teams_role": .dictionary(["ios": .string("guest")]),
            "secret_note": .string(expectedNote)
        ]
        let expectedEndpoint: Endpoint<UpdateUsersResponse> = Endpoint<UpdateUsersResponse>
            .updateUsersPartial(updateUsersPartialRequest: UpdateUsersPartialRequest(
                users: [
                    UpdateUserPartialRequest(id: expectedId, set: expectedSet, unset: ["image"])
                ]
            ))
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_updateUser_makesCorrectAPICall_whenOnlyUnsetProperties() throws {
        // Simulate user already set
        let userPayload: OwnUserResponse = .dummy(userId: .unique, role: .user)
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        currentUserUpdater.updateUserData(
            currentUserId: userPayload.id,
            name: nil,
            imageURL: nil,
            privacySettings: nil,
            role: nil,
            teamsRole: nil,
            userExtraData: nil,
            unset: ["image"],
            completion: { _ in }
        )
        
        // Assert that request is made to the correct endpoint
        let expectedEndpoint: Endpoint<UpdateUsersResponse> = Endpoint<UpdateUsersResponse>
            .updateUsersPartial(updateUsersPartialRequest: UpdateUsersPartialRequest(
                users: [
                    UpdateUserPartialRequest(id: userPayload.id, set: nil, unset: ["image"])
                ]
            ))
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_updateUser_updatesCurrentUserToDatabase() throws {
        // Simulate user already set
        let userPayload: OwnUserResponse = .dummy(userId: .unique, role: .user)
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        // Expected updated user data
        let expectedId = userPayload.id
        let expectedName = String.unique
        let expectedImageUrl = URL.unique()
        let expectedRole = UserRole.anonymous

        // Call update user
        nonisolated(unsafe) var completionCalled = false
        currentUserUpdater.updateUserData(
            currentUserId: expectedId,
            name: expectedName,
            imageURL: expectedImageUrl,
            privacySettings: .init(
                typingIndicators: .init(enabled: false),
                readReceipts: .init(enabled: false)
            ),
            role: expectedRole,
            teamsRole: nil,
            userExtraData: nil,
            unset: [],
            completion: { _ in
                completionCalled = true
            }
        )

        // Simulate API response
        let currentUserUpdateResponse = UpdateUsersResponse.dummy(
            user: OwnUserResponse.dummy(
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
        let userPayload: OwnUserResponse = .dummy(userId: .unique, role: .user)
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        // Call update user
        nonisolated(unsafe) var completionError: Error?
        currentUserUpdater.updateUserData(
            currentUserId: userPayload.id,
            name: .unique,
            imageURL: nil,
            privacySettings: nil,
            role: nil,
            teamsRole: nil,
            userExtraData: nil,
            unset: [],
            completion: { error in
                completionError = error
            }
        )

        // Simulate API error
        let error = TestError()
        apiClient
            .test_simulateResponse(
                Result<UpdateUsersResponse, Error>.failure(error)
            )
        apiClient
            .cleanUp()

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionError as? TestError, error)
    }

    func test_updateUser_whenNoDataProvided_shouldNotMakeAPICall() throws {
        // Simulate user already set
        let userPayload: OwnUserResponse = .dummy(userId: .unique, role: .user)
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
                teamsRole: nil,
                userExtraData: nil,
                unset: [],
                completion: $0
            )
        }

        XCTAssertNil(error)
        XCTAssertNil(apiClient.request_endpoint)
    }

    func test_updateUser_propogatesDatabaseError() throws {
        // Simulate user already set
        let userPayload: OwnUserResponse = .dummy(userId: .unique, role: .user)
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        // Simulate the DB failing with `TestError`
        let testError = TestError()
        database.write_errorResponse = testError

        // Call update user
        nonisolated(unsafe) var completionError: Error?
        currentUserUpdater.updateUserData(
            currentUserId: .unique,
            name: .unique,
            imageURL: nil,
            privacySettings: nil,
            role: nil,
            teamsRole: nil,
            userExtraData: nil,
            unset: [],
            completion: { error in
                completionError = error
            }
        )

        // Simulate API response
        let currentUserUpdateResponse = UpdateUsersResponse.dummy(
            user: userPayload
        )
        apiClient.test_simulateResponse(.success(currentUserUpdateResponse))

        // Check returned error
        AssertAsync.willBeEqual(completionError as? TestError, testError)
    }

    // MARK: addDevice

    func test_addDevice_makesCorrectAPICall() throws {
        let userPayload: OwnUserResponse = .dummy(userId: .unique, role: .user)
        let deviceId = "test"
        let pushProvider = PushProvider.apn
        let providerName = "APN Configuration"

        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        // Mock successful API response
        apiClient.test_mockResponseResult(.success(Response(duration: "")))

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
        let expectedEndpoint = Endpoint<Response>.createDevice(
            createDeviceRequest: CreateDeviceRequest(
                id: deviceId,
                pushProvider: .init(rawValue: pushProvider.rawValue) ?? .unknown,
                pushProviderName: providerName
            )
        )

        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_addDevice_forwardsNetworkError() throws {
        let userPayload: OwnUserResponse = .dummy(userId: .unique, role: .user)

        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        // Mock failure API response
        let error = TestError()
        apiClient.test_mockResponseResult(Result<Response, Error>.failure(error))

        // Call addDevice
        nonisolated(unsafe) var completionCalledError: Error?
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
        let userPayload: OwnUserResponse = .dummy(userId: .unique, role: .user, devices: [.dummy])

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
        apiClient.test_mockResponseResult(.success(Response(duration: "")))

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
        let userPayload: OwnUserResponse = .dummy(userId: .unique, role: .user)
        let deviceId = "test"
        let pushProvider = PushProvider.apn
        let providerName = "APN Configuration"

        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        // Mock successful API response
        apiClient.test_mockResponseResult(.success(Response(duration: "")))

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
        let userPayload: OwnUserResponse = .dummy(userId: .unique, role: .user)

        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        apiClient.test_mockResponseResult(.success(Response(duration: "")))
        let expectation = XCTestExpectation()
        
        // Call removeDevice
        currentUserUpdater.removeDevice(id: "01", currentUserId: userPayload.id) {
            // No error should be returned
            XCTAssertNil($0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: defaultTimeout)
        
        // Assert that request is made to the correct endpoint
        let expectedEndpoint = Endpoint<Response>.deleteDevice(id: "01")
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_removeDevice_forwardsNetworkError() throws {
        let userPayload: OwnUserResponse = .dummy(userId: .unique, role: .user)

        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        apiClient.test_mockResponseResult(.success(Response(duration: "")))
        let expectation = XCTestExpectation()

        // Call removeDevice
        nonisolated(unsafe) var completionCalledError: Error?
        currentUserUpdater.removeDevice(id: "", currentUserId: .unique) {
            completionCalledError = $0
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: defaultTimeout)
        
        // Simulate API error
        let error = TestError()
        apiClient.test_simulateResponse(Result<Response, Error>.failure(error))
        apiClient.cleanUp()

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    func test_removeDevice_successfulResponse_isSavedToDB() throws {
        let userPayload: OwnUserResponse = .dummy(userId: .unique, role: .user, devices: [.dummy])
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
        apiClient.test_simulateResponse(.success(Response(duration: "")))

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
        let payloads: [DeviceResponse] = [.dummy, .dummy]
        let expectedDevices = payloads.map { Device(id: $0.id, createdAt: $0.createdAt) }
        let userPayload: OwnUserResponse = .dummy(userId: .unique, role: .user, devices: payloads)

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
        let expectedEndpoint = Endpoint<ListDevicesResponse>.listDevices()
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_fetchDevices_forwardsNetworkError() throws {
        let userPayload: OwnUserResponse = .dummy(userId: .unique, role: .user)

        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        // Call updateDevices
        nonisolated(unsafe) var completionCalledError: Error?
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
        apiClient.test_simulateResponse(Result<ListDevicesResponse, Error>.failure(error))
        apiClient.cleanUp()

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
        // `weakcurrentUserUpdater` should be deallocated too
        AssertAsync.canBeReleased(&weakcurrentUserUpdater)
    }

    func test_fetchDevices_forwardsDatabaseError() throws {
        let userPayload: OwnUserResponse = .dummy(userId: .unique, role: .user)

        // Save user to the db
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }

        // Simulate the DB failing with `TestError`
        let testError = TestError()
        database.write_errorResponse = testError

        // Call updateDevices
        nonisolated(unsafe) var completionCalledError: Error?
        currentUserUpdater.fetchDevices(currentUserId: .unique) {
            completionCalledError = $0.error
        }

        // Simulate successful API response
        apiClient.test_simulateResponse(.success(ListDevicesResponse.dummy))

        // Check returned error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    func test_fetchDevices_successfulResponse_isSavedToDB() throws {
        let userPayload: OwnUserResponse = .dummy(userId: .unique, role: .user)

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
        
        let dummyDevices = ListDevicesResponse.dummy
        let apiDevices = dummyDevices.devices.map { Device(id: $0.id, createdAt: $0.createdAt) }

        // Call updateDevices
        nonisolated(unsafe) var callbackCalled = false
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
        let referenceEndpoint = Endpoint<MarkReadResponse>.markChannelsRead(markChannelsReadRequest: MarkChannelsReadRequest())

        // WHEN
        currentUserUpdater.markAllRead()

        // THEN
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_markAllRead_successfulResponse_isPropagatedToCompletion() {
        // GIVEN
        nonisolated(unsafe) var completionCalled = false

        // WHEN
        currentUserUpdater.markAllRead { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        apiClient.test_simulateResponse(Result<MarkReadResponse, Error>.success(.init(duration: "")))

        // THEN
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_markAllRead_errorResponse_isPropagatedToCompletion() {
        // GIVEN
        nonisolated(unsafe) var completionCalledError: Error?
        let error = TestError()

        // WHEN
        currentUserUpdater.markAllRead { completionCalledError = $0 }
        apiClient.test_simulateResponse(Result<MarkReadResponse, Error>.failure(error))

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
    
    // MARK: - Load All Unreads
    
    func test_loadAllUnreads_makesCorrectAPICall() {
        // Call loadAllUnreads
        nonisolated(unsafe) var receivedUnreads: CurrentUserUnreads?
        currentUserUpdater.loadAllUnreads { result in
            receivedUnreads = try? result.get()
        }
        
        // Assert request is made to the correct endpoint
        XCTAssertNotNil(apiClient.request_endpoint)
        let endpoint = Endpoint<WrappedUnreadCountsResponse>.unreadCounts()
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(endpoint))
        
        // Create test payload for the response
        let payload = WrappedUnreadCountsResponse.dummy(
            channelType: [
                .dummy(
                    channelCount: 2,
                    channelType: .messaging,
                    unreadCount: 10
                )
            ],
            channels: [
                .dummy(
                    channelId: .init(type: .messaging, id: "channel1"),
                    lastRead: Date(),
                    unreadCount: 5
                ),
                .dummy(
                    channelId: .init(type: .messaging, id: "channel2"),
                    lastRead: Date(),
                    unreadCount: 5
                )
            ],
            threads: [
                .dummy(
                    lastRead: Date(),
                    lastReadMessageId: "message1",
                    parentMessageId: "thread1",
                    unreadCount: 3
                )
            ],
            totalUnreadCount: 10,
            totalUnreadCountByTeam: ["Benfica": 3],
            totalUnreadThreadsCount: 3
        )
        
        // Simulate API response
        apiClient.test_simulateResponse(.success(payload))
        
        // Verify the result is correctly transformed into the model
        XCTAssertEqual(receivedUnreads?.totalUnreadMessagesCount, payload.totalUnreadCount)
        XCTAssertEqual(receivedUnreads?.totalUnreadChannelsCount, payload.channels.count)
        XCTAssertEqual(receivedUnreads?.totalUnreadThreadsCount, payload.totalUnreadThreadsCount)
        XCTAssertEqual(receivedUnreads?.unreadChannels.count, payload.channels.count)
        XCTAssertEqual(receivedUnreads?.unreadThreads.count, payload.threads.count)
        XCTAssertEqual(receivedUnreads?.unreadChannelsByType.count, payload.channelType.count)
        XCTAssertEqual(receivedUnreads?.totalUnreadCountByTeam?["Benfica"], 3)
    }
    
    func test_loadAllUnreads_propagatesNetworkError() {
        // Call loadAllUnreads
        nonisolated(unsafe) var receivedError: Error?
        currentUserUpdater.loadAllUnreads { result in
            if case let .failure(error) = result {
                receivedError = error
            }
        }
        
        // Simulate API error
        let expectedError = TestError()
        apiClient.test_simulateResponse(Result<WrappedUnreadCountsResponse, Error>.failure(expectedError))
        
        // Verify the error is propagated
        XCTAssertEqual(receivedError as? TestError, expectedError)
    }
    
    // MARK: - Load Active Live Locations
    
    func test_loadActiveLiveLocations_makesCorrectAPICall() {
        // WHEN
        currentUserUpdater.loadActiveLiveLocations { _ in }
        
        // THEN
        let endpoint = Endpoint<SharedLocationsResponse>.getUserLiveLocations()
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(endpoint))
    }
    
    func test_loadActiveLiveLocations_successfulResponse_savesToDBAndReturnsModels() throws {
        // GIVEN
        let payloads = [
            SharedLocationResponseData.dummy(latitude: 10, longitude: 20, endAt: Date().addingTimeInterval(100)),
            SharedLocationResponseData.dummy(latitude: 30, longitude: 40, endAt: Date().addingTimeInterval(200))
        ]
        let response = SharedLocationsResponse.dummy(activeLiveLocations: payloads)
        nonisolated(unsafe) var result: Result<[SharedLocation], Error>?
        
        // WHEN
        let expectation = self.expectation(description: "loadActiveLiveLocations")
        currentUserUpdater.loadActiveLiveLocations {
            result = $0
            expectation.fulfill()
        }
        apiClient.test_simulateResponse(.success(response))

        waitForExpectations(timeout: defaultTimeout)

        // THEN
        let sharedLocations = try result?.get()
        XCTAssertEqual(sharedLocations?.count, payloads.count)
        for (model, payload) in zip(sharedLocations ?? [], payloads) {
            XCTAssertEqual(model.messageId, payload.messageId)
            XCTAssertEqual(model.channelId.rawValue, payload.channelCid)
            XCTAssertEqual(model.latitude, Double(payload.latitude))
            XCTAssertEqual(model.longitude, Double(payload.longitude))
            XCTAssertEqual(model.endAt?.timeIntervalSince1970, payload.endAt?.timeIntervalSince1970)
            XCTAssertEqual(model.createdByDeviceId, payload.createdByDeviceId)
        }
    }
    
    func test_loadActiveLiveLocations_propagatesNetworkError() {
        // GIVEN
        let expectedError = TestError()
        nonisolated(unsafe) var result: Result<[SharedLocation], Error>?
        
        // WHEN
        currentUserUpdater.loadActiveLiveLocations {
            result = $0
        }
        apiClient.test_simulateResponse(Result<SharedLocationsResponse, Error>.failure(expectedError))
        
        // THEN
        switch result {
        case .failure(let error as TestError):
            XCTAssertEqual(error, expectedError)
        default:
            XCTFail("Expected TestError")
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

    // MARK: - setPushPreference

    func test_setPushPreference_makesCorrectAPICall() throws {
        // GIVEN
        let preference = PushPreferenceInput(
            channelCid: nil,
            chatLevel: PushPreferenceInput.PushPreferenceInputChatLevel(rawValue: "mentions"),
            disabledUntil: nil,
            removeDisable: true
        )

        // WHEN
        currentUserUpdater.setPushPreference(preference) { _ in }

        // THEN
        let expectedEndpoint: Endpoint<UpsertPushPreferencesResponse> = Endpoint<UpsertPushPreferencesResponse>
            .updatePushNotificationPreferences(
                upsertPushPreferencesRequest: UpsertPushPreferencesRequest(preferences: [preference])
            )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_setPushPreference_successfulResponse_savesToDatabase() throws {
        // GIVEN
        let userId = UserId.unique
        let disabledUntil = "2024-12-31T23:59:59.999Z".toDate()
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: .dummy(userId: userId, role: .user))
        }

        let preference = PushPreferenceInput(
            channelCid: nil,
            chatLevel: PushPreferenceInput.PushPreferenceInputChatLevel(rawValue: "all"),
            disabledUntil: disabledUntil,
            removeDisable: true
        )

        let response = UpsertPushPreferencesResponse.dummy(
            userChannelPreferences: [:],
            userPreferences: [
                userId: .dummy(
                    chatLevel: nil,
                    disabledUntil: disabledUntil
                )
            ]
        )

        // WHEN
        nonisolated(unsafe) var completionCalled = false
        nonisolated(unsafe) var receivedPreference: PushPreference?
        currentUserUpdater.setPushPreference(preference) { result in
            XCTAssertNil(result.error)
            receivedPreference = try? result.get()
            completionCalled = true
        }

        apiClient.test_simulateResponse(.success(response))

        // THEN
        AssertAsync.willBeTrue(completionCalled)
        AssertAsync.willBeEqual(receivedPreference?.level, .all)
        AssertAsync.willBeEqual(receivedPreference?.disabledUntil, disabledUntil)

        var currentUser: CurrentChatUser? {
            try? database.viewContext.currentUser?.asModel()
        }
        AssertAsync.willBeEqual(currentUser?.pushPreference?.level, .all)
        AssertAsync.willBeEqual(currentUser?.pushPreference?.disabledUntil, disabledUntil)
    }

    func test_setPushPreference_propagatesNetworkError() {
        // GIVEN
        let preference = PushPreferenceInput(
            channelCid: nil,
            chatLevel: PushPreferenceInput.PushPreferenceInputChatLevel(rawValue: "mentions"),
            disabledUntil: nil,
            removeDisable: true
        )

        // WHEN
        nonisolated(unsafe) var completionError: Error?
        currentUserUpdater.setPushPreference(preference) { result in
            if case let .failure(error) = result {
                completionError = error
            }
        }

        let error = TestError()
        apiClient.test_simulateResponse(Result<UpsertPushPreferencesResponse, Error>.failure(error))

        // THEN
        AssertAsync.willBeEqual(completionError as? TestError, error)
    }

    func test_setPushPreference_whenNoUserPreferences_returnsError() {
        // GIVEN
        let preference = PushPreferenceInput(
            channelCid: nil,
            chatLevel: PushPreferenceInput.PushPreferenceInputChatLevel(rawValue: "mentions"),
            disabledUntil: nil,
            removeDisable: true
        )

        let response = UpsertPushPreferencesResponse.dummy()

        // WHEN
        nonisolated(unsafe) var completionError: Error?
        currentUserUpdater.setPushPreference(preference) { result in
            if case let .failure(error) = result {
                completionError = error
            }
        }

        apiClient.test_simulateResponse(.success(response))

        // THEN
        AssertAsync.willBeTrue(completionError is ClientError.CurrentUserDoesNotExist)
    }

    // MARK: - Mark Channels Delivered

    func test_markMessagesAsDelivered_makesCorrectAPICall() {
        // GIVEN
        let deliveredMessages = [
            MessageDeliveryInfo(channelId: .init(type: .messaging, id: "channel1"), messageId: .unique),
            MessageDeliveryInfo(channelId: .init(type: .livestream, id: "channel2"), messageId: .unique)
        ]

        // WHEN
        currentUserUpdater.markMessagesAsDelivered(deliveredMessages)

        // THEN
        let expectedPayload = MarkDeliveredRequest(
            latestDeliveredMessages: deliveredMessages.map { DeliveredMessagePayload(cid: $0.channelId.rawValue, id: $0.messageId) }
        )
        let expectedEndpoint = Endpoint<MarkDeliveredResponse>.markDelivered(markDeliveredRequest: expectedPayload)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_markMessagesAsDelivered_successfulResponse_isPropagatedToCompletion() {
        // GIVEN
        let deliveredMessages = [
            MessageDeliveryInfo(channelId: .init(type: .messaging, id: "channel1"), messageId: .unique)
        ]
        nonisolated(unsafe) var completionCalled = false

        // WHEN
        currentUserUpdater.markMessagesAsDelivered(deliveredMessages) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        apiClient.test_simulateResponse(Result<MarkDeliveredResponse, Error>.success(.init(duration: "")))

        // THEN
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_markMessagesAsDelivered_errorResponse_isPropagatedToCompletion() {
        // GIVEN
        let deliveredMessages = [
            MessageDeliveryInfo(channelId: .init(type: .messaging, id: "channel1"), messageId: .unique)
        ]
        nonisolated(unsafe) var completionCalledError: Error?
        let error = TestError()

        // WHEN
        currentUserUpdater.markMessagesAsDelivered(
            deliveredMessages
        ) {
            completionCalledError = $0
        }
        apiClient.test_simulateResponse(Result<MarkDeliveredResponse, Error>.failure(error))

        // THEN
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
}
