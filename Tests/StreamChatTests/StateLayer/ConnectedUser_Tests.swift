//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ConnectedUser_Tests: XCTestCase {
    private var connectedUser: ConnectedUser!
    private var connectedUserId: UserId!
    private var env: TestEnvironment!
    
    override func setUpWithError() throws {
        connectedUserId = .unique
        env = TestEnvironment()
    }

    override func tearDownWithError() throws {
        env.cleanUp()
        connectedUser = nil
        connectedUserId = nil
        env = nil
    }

    func test_updateUser_whenAPIRequestSucceeds_thenStateUpdates() async throws {
        try await setUpConnectedUser(usesMockedUpdaters: false)
        await XCTAssertEqual("InitialName", connectedUser.state.user.name)
        await XCTAssertEqual(UserRole.admin, connectedUser.state.user.userRole)
        
        let changedName = "Name"
        let apiResult = CurrentUserUpdateResponse(
            user: currentUserPayload(
                name: changedName,
                role: .user
            )
        )
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResult))
        try await connectedUser.update(
            name: changedName,
            role: .user
        )

        await XCTAssertEqual(changedName, connectedUser.state.user.name)
        await XCTAssertEqual(UserRole.user, connectedUser.state.user.userRole)
    }
    
    func test_markAllChannelsRead_whenAPIRequestSucceeds_thenMarkAllSucceeds() async throws {
        try await setUpConnectedUser(usesMockedUpdaters: true)
        env.currentUserUpdaterMock.markAllRead_completion_result = .success(())
        try await connectedUser.markAllChannelsRead()
    }
    
    func test_loadDevices_whenAPIRequestSucceeds_thenResultsAreReturnedAndStateUpdates() async throws {
        try await setUpConnectedUser(usesMockedUpdaters: false)
        
        let apiResult = DeviceListPayload(devices: [.dummy, .dummy, .dummy])
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResult))
        
        let devices = try await connectedUser.loadDevices()
        // There is no sorting for devices, therefore force the order when comparing (stored as Set in DB)
        XCTAssertEqual(apiResult.devices.map(\.id).sorted(), devices.map(\.id).sorted())
        await XCTAssertEqual(apiResult.devices.map(\.id).sorted(), connectedUser.state.user.devices.map(\.id).sorted())
    }
    
    func test_loadDevices_whenExistingFetchedDevices_thenDatabaseIsResetToFetchedDevices() async throws {
        // Set initial state where we have devices stored in DB
        try await env.client.databaseContainer.write { session in
            try session.saveCurrentUser(payload: self.currentUserPayload(deviceCount: 2))
        }
        
        // Fetch devices which resets the device list
        try await setUpConnectedUser(usesMockedUpdaters: false)
        let apiResult = DeviceListPayload(devices: [.dummy, .dummy, .dummy])
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResult))
        let devices = try await connectedUser.loadDevices()
        
        XCTAssertEqual(apiResult.devices.map(\.id).sorted(), devices.map(\.id).sorted())
        await XCTAssertEqual(apiResult.devices.map(\.id).sorted(), connectedUser.state.user.devices.map(\.id).sorted())
    }
    
    func test_addDevices_whenAPIRequestSucceeds_thenStateUpdates() async throws {
        try await setUpConnectedUser(usesMockedUpdaters: false)
        await XCTAssertEqual(0, connectedUser.state.user.devices.count)
        
        env.client.mockAPIClient.test_mockResponseResult(.success(EmptyResponse()))
        try await connectedUser.addDevice(.apn(token: Data("test123".utf8)))
        
        // Converted to hex (test123 > 74657374313233)
        await XCTAssertEqual(["74657374313233"], connectedUser.state.user.devices.map(\.id))
    }
    
    func test_removeDevice_whenAPIRequestSucceeds_thenStateUpdates() async throws {
        try await setUpConnectedUser(usesMockedUpdaters: false, initialDeviceCount: 2)
        
        env.client.mockAPIClient.test_mockResponseResult(.success(EmptyResponse()))
        var devices = await connectedUser.state.user.devices
        let deviceToRemove = try XCTUnwrap(devices.popLast()?.id)
        try await connectedUser.removeDevice(deviceToRemove)
        
        await XCTAssertEqual(false, connectedUser.state.user.devices.contains(where: { $0.id == deviceToRemove }))
        await XCTAssertEqual(devices.map(\.id).sorted(), connectedUser.state.user.devices.map(\.id))
    }
    
    func test_muteUser_whenUpdatedSucceeds_thenMuteUserSucceeds() async throws {
        try await setUpConnectedUser(usesMockedUpdaters: true)
        
        env.userUpdaterMock.muteUser_completion_result = .success(())
        let id = UserId.unique
        try await connectedUser.muteUser(id)
        XCTAssertEqual(id, env.userUpdaterMock.muteUser_userId)
    }
    
    func test_unmuteUser_whenUpdatedSucceeds_thenUnmuteUserSucceeds() async throws {
        try await setUpConnectedUser(usesMockedUpdaters: true)
        
        env.userUpdaterMock.unmuteUser_completion_result = .success(())
        let id = UserId.unique
        try await connectedUser.unmuteUser(id)
        XCTAssertEqual(id, env.userUpdaterMock.unmuteUser_userId)
    }
    
    func test_flagUser_whenUpdatedSucceeds_thenFlagUserSucceeds() async throws {
        try await setUpConnectedUser(usesMockedUpdaters: true)
        
        env.userUpdaterMock.flagUser_completion_result = .success(())
        let id = UserId.unique
        try await connectedUser.flag(id)
        XCTAssertEqual(true, env.userUpdaterMock.flagUser_flag)
        XCTAssertEqual(id, env.userUpdaterMock.flagUser_userId)
    }
    
    func test_unflagUser_whenUpdatedSucceeds_thenUnflagUserSucceeds() async throws {
        try await setUpConnectedUser(usesMockedUpdaters: true)
        
        env.userUpdaterMock.flagUser_completion_result = .success(())
        let id = UserId.unique
        try await connectedUser.unflag(id)
        XCTAssertEqual(false, env.userUpdaterMock.flagUser_flag)
        XCTAssertEqual(id, env.userUpdaterMock.flagUser_userId)
    }
    
    func test_blockUser_whenUpdatedSucceeds_thenBlockUserSucceeds() async throws {
        try await setUpConnectedUser(usesMockedUpdaters: true)
        
        env.userUpdaterMock.blockUser_completion_result = .success(())
        let id = UserId.unique
        try await connectedUser.blockUser(id)
        XCTAssertEqual(id, env.userUpdaterMock.blockUser_userId)
    }
    
    func test_unblockUser_whenUpdatedSucceeds_thenUnblockUserSucceeds() async throws {
        try await setUpConnectedUser(usesMockedUpdaters: true)
        
        env.userUpdaterMock.unblockUser_completion_result = .success(())
        let id = UserId.unique
        try await connectedUser.unblockUser(id)
        XCTAssertEqual(id, env.userUpdaterMock.unblockUser_userId)
    }
    
    // MARK: - Test Data
    
    @MainActor private func setUpConnectedUser(usesMockedUpdaters: Bool, loadState: Bool = true, initialDeviceCount: Int = 0) async throws {
        var user: CurrentChatUser!
        try await env.client.databaseContainer.write { session in
            user = try session.saveCurrentUser(payload: self.currentUserPayload(deviceCount: initialDeviceCount)).asModel()
        }
        env.client.mockAuthenticationRepository.mockedCurrentUserId = connectedUserId
        connectedUser = ConnectedUser(
            user: user,
            client: env.client,
            environment: env.connectedUserEnvironment(
                usesMockedUpdaters: usesMockedUpdaters
            )
        )
        if loadState {
            _ = connectedUser.state
        }
    }
    
    private func currentUserPayload(name: String = "InitialName", deviceCount: Int = 0, role: UserRole = .admin) -> CurrentUserPayload {
        let devices = (0..<deviceCount).map { _ in DevicePayload.dummy }
        return CurrentUserPayload.dummy(
            userId: connectedUserId,
            name: name,
            role: role,
            devices: devices
        )
    }
}

extension ConnectedUser_Tests {
    final class TestEnvironment {
        let client: ChatClient_Mock
        private(set) var state: MessageSearchState!
        private(set) var currentUserUpdater: CurrentUserUpdater!
        private(set) var currentUserUpdaterMock: CurrentUserUpdater_Mock!
        private(set) var userUpdater: UserUpdater!
        private(set) var userUpdaterMock: UserUpdater_Mock!
        
        func cleanUp() {
            client.cleanUp()
            currentUserUpdaterMock.cleanUp()
            userUpdaterMock.cleanUp()
        }
        
        init() {
            client = ChatClient_Mock(
                config: ChatClient_Mock.defaultMockedConfig
            )
        }
        
        func connectedUserEnvironment(usesMockedUpdaters: Bool) -> ConnectedUser.Environment {
            ConnectedUser.Environment(
                currentUserUpdaterBuilder: { [unowned self] in
                    self.currentUserUpdater = CurrentUserUpdater(database: $0, apiClient: $1)
                    self.currentUserUpdaterMock = CurrentUserUpdater_Mock(database: $0, apiClient: $1)
                    return usesMockedUpdaters ? currentUserUpdaterMock : currentUserUpdater
                },
                userUpdaterBuilder: { [unowned self] in
                    self.userUpdater = UserUpdater(database: $0, apiClient: $1)
                    self.userUpdaterMock = UserUpdater_Mock(database: $0, apiClient: $1)
                    return usesMockedUpdaters ? userUpdaterMock : userUpdater
                }
            )
        }
    }
}
