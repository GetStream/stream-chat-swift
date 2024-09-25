//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class CurrentUserController_Tests: XCTestCase {
    private var env: TestEnvironment!
    private var client: ChatClient!
    private var controller: CurrentChatUserController!
    private var controllerCallbackQueueID: UUID!
    private var callbackQueueID: UUID { controllerCallbackQueueID }

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        env = TestEnvironment()
        client = ChatClient.mock
        controller = CurrentChatUserController(client: client, environment: env.currentUserControllerEnvironment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }

    override func tearDown() {
        client.completeConnectionIdWaiters(connectionId: nil)
        client.completeTokenWaiters(token: nil)

        controllerCallbackQueueID = nil
        client.mockAPIClient.cleanUp()
        env.currentUserUpdater?.cleanUp()

        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }

        super.tearDown()
    }

    // MARK: Controller

    // MARK: - currentUser tests

    func test_currentUser_startsObserving_returnsCurrentUserObserverItem() {
        let expectedId = UserId.unique
        let expectedUnreadCount = UnreadCount(channels: .unique, messages: .unique, threads: .unique)

        env.currentUserObserverItem = .mock(id: expectedId, unreadCount: expectedUnreadCount)

        XCTAssertEqual(controller.currentUser?.id, expectedId)
        XCTAssertTrue(env.currentUserObserver.startObservingCalled)
    }

    // MARK: - Synchronize tests

    func test_synchronize_localDataIsAvailable() {
        let expectedId = UserId.unique
        let expectedUnreadCount = UnreadCount(channels: .unique, messages: .unique, threads: .unique)

        env.currentUserObserverItem = .mock(id: expectedId, unreadCount: expectedUnreadCount)

        let expectation = self.expectation(description: "synchronize called")

        controller.synchronize { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        // the sync completion is called when there is a connectionID
        client.completeConnectionIdWaiters(connectionId: UUID().uuidString)

        // Assert client is assigned correctly
        XCTAssertTrue(controller.client === client)

        // Assert user is correct
        XCTAssertEqual(controller.currentUser?.id, expectedId)

        // Assert unread-count is correct
        XCTAssertEqual(controller.unreadCount, expectedUnreadCount)

        waitForExpectations(timeout: defaultTimeout, handler: nil)
    }

    func test_synchronize_changesState_and_propagatesObserverErrorOnCallbackQueue() {
        // Update observer to throw the error.
        let observerError = TestError()
        env.currentUserObserverStartUpdatingError = observerError

        // Simulate `synchronize` call.
        var synchronizeError: Error?
        controller.synchronize { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            synchronizeError = error
        }

        // Assert controller is in `localDataFetchFailed` state.
        XCTAssertEqual(controller.state, .localDataFetchFailed(ClientError(with: observerError)))

        // Assert error from observer is forwarded.
        AssertAsync.willBeEqual(synchronizeError as? ClientError, ClientError(with: observerError))
    }

    func test_synchronize_changesControllerState() {
        // Check if controller has initialized state initially.
        XCTAssertEqual(controller.state, .initialized)

        // Simulate current user
        env.currentUserObserverItem = .mock(id: .unique)

        var synchronizeCalled = false
        controller.synchronize { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            synchronizeCalled = true
        }

        // Simulate connection successful
        client.simulateProvidedConnectionId(connectionId: .unique)

        AssertAsync {
            Assert.willBeEqual(self.controller.state, .remoteDataFetched)
            Assert.willBeTrue(synchronizeCalled)
        }
    }

    func test_synchronize_changesControllerStateOnError() {
        // Check if controller has initialized state initially.
        XCTAssertEqual(controller.state, .initialized)

        // Simulate current user
        env.currentUserObserverItem = .mock(id: .unique)

        var synchronizeError: Error?
        controller.synchronize { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            synchronizeError = error
        }

        // Simulate connection not successful
        client.simulateProvidedConnectionId(connectionId: nil)

        AssertAsync {
            Assert.willBeEqual(self.controller.state, .remoteDataFetchFailed(.ConnectionNotSuccessful()))
            Assert.willBeEqual(synchronizeError as? ClientError, ClientError.ConnectionNotSuccessful())
        }
    }

    /// This test simulates a bug where the `currentUser` field was not updated if it wasn't
    /// touched before calling synchronize.
    func test_currentUserIsFetched_afterCallingSynchronize() throws {
        // Simulate `synchronize` call
        controller.synchronize()

        // Create the current user in the DB
        let userId = UserId.unique
        try client.databaseContainer.createCurrentUser(id: userId)

        // Assert the existing user is loaded
        XCTAssertEqual(controller.currentUser?.id, userId)
    }

    // MARK: - Delegate

    func test_delegate_isAssignedCorrectly() {
        // Set the delegate
        let delegate = UserController_Delegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Assert the delegate is assigned correctly
        XCTAssert(controller.delegate === delegate)
    }

    func test_delegate_isReferencedWeakly() {
        // Create the delegate
        var delegate: UserController_Delegate? = .init(expectedQueueId: callbackQueueID)

        // Set the delegate
        controller.delegate = delegate

        // Stop keeping a delegate alive
        delegate = nil

        // Assert delegate is deallocated
        XCTAssertNil(controller.delegate)
    }

    func test_delegate_isNotifiedAboutCreatedUser() throws {
        // Call synchronize to get updates from DB
        controller.synchronize()

        let extraData: [String: RawJSON] = [:]
        let currentUserPayload: CurrentUserPayload = .dummy(
            userId: .unique,
            role: .user,
            extraData: extraData
        )

        // Set the delegate
        let delegate = UserController_Delegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Simulate saving current user to a database
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: currentUserPayload)
        }

        // Assert delegate received correct entity change
        AssertAsync {
            Assert.willBeEqual(delegate.didChangeCurrentUser_change?.fieldChange(\.id), .create(currentUserPayload.id))
            Assert.willBeEqual(delegate.didChangeCurrentUser_change?.fieldChange(\.extraData), .create(extraData))
        }
    }

    func test_delegate_isNotifiedAboutUpdatedUser() throws {
        // Call synchronize to get updates from DB
        controller.synchronize()

        var extraData: [String: RawJSON] = [:]
        var currentUserPayload: CurrentUserPayload = .dummy(
            userId: .unique,
            role: .user,
            extraData: extraData
        )

        // Set the delegate
        let delegate = UserController_Delegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Simulate saving current user to a database
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: currentUserPayload)
        }

        // Update current user data
        extraData = [:]
        currentUserPayload = .dummy(
            userId: currentUserPayload.id,
            role: currentUserPayload.role,
            extraData: extraData
        )

        // Simulate updating current user in a database
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: currentUserPayload)
        }

        // Assert delegate received correct entity change
        AssertAsync {
            Assert.willBeEqual(delegate.didChangeCurrentUser_change?.fieldChange(\.id), .update(currentUserPayload.id))
            Assert.willBeEqual(delegate.didChangeCurrentUser_change?.fieldChange(\.extraData), .update(extraData))
        }
    }

    func test_delegate_isNotifiedAboutUnreadCount_whenUserIsCreated() throws {
        // Call synchronize to get updates from DB
        controller.synchronize()

        let unreadCount = UnreadCountPayload(channels: 10, messages: 15, threads: 10)

        // Set the delegate
        let delegate = UserController_Delegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Simulate saving current user to a database
        try client.databaseContainer.writeSynchronously {
            let currentUserPayload: CurrentUserPayload = .dummy(
                userId: .unique,
                role: .user,
                unreadCount: unreadCount
            )
            try $0.saveCurrentUser(payload: currentUserPayload)
        }

        wait(for: [delegate.didChangeCurrentUserUnreadCountExpectation], timeout: defaultTimeout)
        
        // Assert delegate received correct unread count
        let delegateUnreadCount = delegate.didChangeCurrentUserUnreadCount_count
        XCTAssertTrue(delegateUnreadCount?.isEqual(toPayload: unreadCount) == true)
    }

    // MARK: - Updating current user

    func test_updateUserData_callCurrentUserUpdater_withCorrectValues() {
        // Simulate `connectUser`
        client.authenticationRepository.setMockToken()

        let expectedName = String.unique
        let expectedImageUrl = URL.unique()

        controller.updateUserData(
            name: expectedName,
            imageURL: expectedImageUrl,
            privacySettings: .init(
                typingIndicators: .init(enabled: true), readReceipts: .init(enabled: true)
            ),
            userExtraData: [:]
        )

        // Assert udpater is called with correct data
        XCTAssertEqual(env.currentUserUpdater.updateUserData_name, expectedName)
        XCTAssertEqual(env.currentUserUpdater.updateUserData_imageURL, expectedImageUrl)
        XCTAssertEqual(env.currentUserUpdater.updateUserData_privacySettings?.typingIndicators?.enabled, true)
        XCTAssertEqual(env.currentUserUpdater.updateUserData_privacySettings?.readReceipts?.enabled, true)
        XCTAssertNotNil(env.currentUserUpdater.updateUserData_completion)
    }

    func test_updateUserData_propagatesError() throws {
        // Simulate `connectUser`
        client.authenticationRepository.setMockToken()

        var completionError: Error?
        controller.updateUserData(name: .unique, imageURL: .unique(), userExtraData: [:]) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error.
        let networkError = TestError()
        env.currentUserUpdater.updateUserData_completion?(networkError)

        // Assert error is propogated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_updateUserData_propagatesNilError() throws {
        // Simulate `connectUser`
        client.authenticationRepository.setMockToken()

        var completionIsCalled = false
        controller
            .updateUserData(name: .unique, imageURL: .unique(), userExtraData: [:]) { [callbackQueueID] error in
                // Assert callback queue is correct.
                AssertTestQueue(withId: callbackQueueID)
                // Assert there is no error.
                XCTAssertNil(error)
                completionIsCalled = true
            }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful network response.
        env.currentUserUpdater.updateUserData_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.currentUserUpdater.updateUserData_completion = nil

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_updateUser_whenCurrentUserDoesNotExist_shouldError() throws {
        let error = try waitFor {
            controller.updateUserData(
                name: .unique,
                imageURL: nil,
                userExtraData: [:],
                completion: $0
            )
        }

        XCTAssert(error is ClientError.CurrentUserDoesNotExist)
    }

    func test_updateUser_doesNotDeadlock() throws {
        // GIVEN
        // Simulate saving current user to a database
        client.authenticationRepository.setMockToken()

        // WHEN
        // updateUser is called from background queue
        DispatchQueue.global().async {
            self.controller.updateUserData()
        }

        // THEN
        // updateUser is called from main queue and actually finishes
        delayExecution(of: { completion in
            self.controller.updateUserData(completion: completion)
        }, onCompletion: {
            self.env.currentUserUpdater.updateUserData_completion?(nil)
        })
    }

    // MARK: - Device endpoints

    // MARK: synchronizeDevices

    func test_synchronizeDevices_whenRequestSuccess_completionCalledWithoutError() throws {
        // Simulate `connectUser`
        client.authenticationRepository.setMockToken()

        var completionError: Error?
        controller.synchronizeDevices { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate successful network call.
        env.currentUserUpdater.fetchDevices_completion?(.success([]))

        AssertAsync.willBeNil(completionError)
    }

    func test_synchronizeDevices_whenRequestFails_propagatesError() {
        // Simulate `connectUser`
        client.authenticationRepository.setMockToken()

        var completionError: Error?
        controller.synchronizeDevices { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error.
        let networkError = TestError()
        env.currentUserUpdater.fetchDevices_completion?(.failure(networkError))

        // Assert error is propogated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_synchronizeDevices__whenCurrentUserDoesNotExist_propagatesError() throws {
        let error = try waitFor {
            controller.synchronizeDevices(completion: $0)
        }

        XCTAssert(error is ClientError.CurrentUserDoesNotExist)
    }

    func test_synchronizeDevices_doesNotDeadlock() throws {
        // GIVEN
        // Simulate saving current user to a database
        client.authenticationRepository.setMockToken()

        // WHEN
        // updateUser is called from background queue
        DispatchQueue.global().async {
            self.controller.synchronizeDevices()
        }

        // THEN
        // synchronizeDevices is called from main queue and actually finishes
        delayExecution(of: { completion in
            self.controller.synchronizeDevices(completion: completion)
        }, onCompletion: {
            self.env.currentUserUpdater.fetchDevices_completion?(.success([]))
        })
    }

    // MARK: addDevice

    func test_addDevice_whenPushProviderIsAPN_callsCurrentUserUpdaterWithCorrectValues() {
        // Simulate `connectUser`
        client.authenticationRepository.setMockToken()

        let expectedDeviceToken = "test".data(using: .utf8)!

        controller.addDevice(.apn(token: expectedDeviceToken))

        // Assert updater is called with correct data
        XCTAssertEqual(env.currentUserUpdater.addDevice_id, expectedDeviceToken.deviceId)
        XCTAssertEqual(env.currentUserUpdater.addDevice_pushProvider, PushProvider.apn)
        XCTAssertNotNil(env.currentUserUpdater.addDevice_completion)
    }

    func test_addDevice_whenPushProviderIsFirebase_callsCurrentUserUpdaterWithCorrectValues() {
        // Simulate `connectUser`
        client.authenticationRepository.setMockToken()

        let expectedDeviceId = "test"

        controller.addDevice(.firebase(token: expectedDeviceId))

        // Assert updater is called with correct data
        XCTAssertEqual(env.currentUserUpdater.addDevice_id, expectedDeviceId)
        XCTAssertEqual(env.currentUserUpdater.addDevice_pushProvider, PushProvider.firebase)
        XCTAssertNotNil(env.currentUserUpdater.addDevice_completion)
    }

    func test_addDevice_propagatesError() throws {
        // Simulate `connectUser`
        client.authenticationRepository.setMockToken()

        var completionError: Error?
        controller.addDevice(.firebase(token: "test")) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error.
        let networkError = TestError()
        env.currentUserUpdater.addDevice_completion?(networkError)

        // Assert error is propogated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_addDevice_propagatesNilError() throws {
        // Simulate `connectUser`
        client.authenticationRepository.setMockToken()

        var completionIsCalled = false
        controller.addDevice(.firebase(token: "test")) { [callbackQueueID] error in
            // Assert callback queue is correct.
            AssertTestQueue(withId: callbackQueueID)
            // Assert there is no error.
            XCTAssertNil(error)
            completionIsCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful network response.
        env.currentUserUpdater.addDevice_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.currentUserUpdater.addDevice_completion = nil

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_addDevice_whenCurrentUserDoesNotExist_shouldError() throws {
        client.authenticationRepository.logOutUser()

        let error = try waitFor {
            controller.addDevice(.firebase(token: "test"), completion: $0)
        }

        XCTAssert(error is ClientError.CurrentUserDoesNotExist)
    }

    func test_addDevice_doesNotDeadlock() throws {
        // GIVEN
        // Simulate saving current user to a database
        client.authenticationRepository.setMockToken()

        // WHEN
        // updateUser is called from background queue
        DispatchQueue.global().async {
            self.controller.addDevice(.apn(token: .init()))
        }

        // THEN
        // addDevice is called from main queue and actually finishes
        delayExecution(of: { completion in
            self.controller.addDevice(.apn(token: .init()), completion: completion)
        }, onCompletion: {
            self.env.currentUserUpdater.addDevice_completion?(nil)
        })
    }

    // MARK: removeDevice

    func test_removeDevice_callCurrentUserUpdater_withCorrectValues() {
        // Simulate `connectUser`
        client.authenticationRepository.setMockToken()

        let expectedId = String.unique

        controller.removeDevice(id: expectedId)

        // Assert udpater is called with correct data
        XCTAssertEqual(env.currentUserUpdater.removeDevice_id, expectedId)
        XCTAssertNotNil(env.currentUserUpdater.removeDevice_completion)
    }

    func test_removeDevice_propagatesError() throws {
        // Simulate `connectUser`
        client.authenticationRepository.setMockToken()

        let expectedId = String.unique

        var completionError: Error?
        controller.removeDevice(id: expectedId) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error.
        let networkError = TestError()
        env.currentUserUpdater.removeDevice_completion?(networkError)

        // Assert error is propogated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_removeDevice_propagatesNilError() throws {
        // Simulate `connectUser`
        client.authenticationRepository.setMockToken()

        let expectedId = String.unique

        var completionIsCalled = false
        controller.removeDevice(id: expectedId) { [callbackQueueID] error in
            // Assert callback queue is correct.
            AssertTestQueue(withId: callbackQueueID)
            // Assert there is no error.
            XCTAssertNil(error)
            completionIsCalled = true
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful network response.
        env.currentUserUpdater.removeDevice_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.currentUserUpdater.removeDevice_completion = nil

        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_removeDevice_whenCurrentUserDoesNotExist_shouldError() throws {
        client.authenticationRepository.logOutUser()

        let error = try waitFor {
            controller.removeDevice(id: .unique, completion: $0)
        }

        XCTAssert(error is ClientError.CurrentUserDoesNotExist)
    }

    func test_removeDevice_doesNotDeadlock() throws {
        // GIVEN
        // Simulate saving current user to a database
        client.authenticationRepository.setMockToken()

        // WHEN
        // updateUser is called from background queue
        DispatchQueue.global().async {
            self.controller.removeDevice(id: .unique)
        }

        // THEN
        // updateUser is called from main queue and actually finishes
        delayExecution(of: { completion in
            self.controller.removeDevice(id: .unique, completion: completion)
        }, onCompletion: {
            self.env.currentUserUpdater.removeDevice_completion?(nil)
        })
    }

    // MARK: - Reload user if needed

    func test_reloadUserIfNeeded_callsClientUpdater_and_propagatesTheResult() throws {
        let authenticationRepository = try XCTUnwrap(client.authenticationRepository as? AuthenticationRepository_Mock)
        for error in [nil, TestError()] {
            // Simulate `reloadUserIfNeeded` and capture the result.
            authenticationRepository.refreshTokenResult = error.map { .failure($0) } ?? .success(())

            let expectation = self.expectation(description: "reloadCompletes")
            var reloadUserIfNeededCompletionError: Error?
            controller.reloadUserIfNeeded { [callbackQueueID] error in
                AssertTestQueue(withId: callbackQueueID)
                reloadUserIfNeededCompletionError = error
                expectation.fulfill()
            }

            waitForExpectations(timeout: defaultTimeout)

            // Assert `error` is propagated.
            XCTAssertEqual(reloadUserIfNeededCompletionError as? TestError, error)
        }
    }

    // MARK: - Mark all read

    func test_markAllRead_callsChannelListUpdater() {
        // GIVEN
        var completionCalled = false

        // WHEN
        controller.markAllRead { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }

        env.currentUserUpdater!.markAllRead_completion?(nil)

        // THEN
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_markAllRead_keepsControllerAlive() {
        // GIVEN
        weak var weakController = controller

        // WHEN
        controller.markAllRead { _ in }

        controller = nil

        // THEN
        AssertAsync.staysTrue(weakController != nil)
    }

    func test_markAllRead_propagatesErrorFromUpdater() {
        // GIVEN
        var completionCalledError: Error?
        let testError = TestError()

        // WHEN
        controller.markAllRead { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }

        env.currentUserUpdater!.markAllRead_completion?(testError)

        // THEN
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    // Delay execution for a bit to make sure background thread acquires lock
    // (from Atomic, in EntityDatabaseObserver.item) if we don't sleep, main thread acquires lock first
    // & no deadlock occurs
    private func delayExecution(of function: @escaping (((Error?) -> Void)?) -> Void, onCompletion: (() -> Void)?) {
        let exp = expectation(description: "completion called")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            function() { _ in
                exp.fulfill()
            }
            onCompletion?()
        }

        wait(for: [exp], timeout: defaultTimeout)
    }
    
    // MARK: - Delete All Attachment Downloads
    
    func test_deleteAllLocalAttachmentDownloads_propagatesErrorFromUpdater() {
        let testError = TestError()
        let expectation = XCTestExpectation()
        controller.deleteAllLocalAttachmentDownloads { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertEqual(testError, error as? TestError)
            expectation.fulfill()
        }
        env.currentUserUpdater.deleteAllLocalAttachmentDownloads_completion?(testError)
        wait(for: [expectation], timeout: defaultTimeout)
    }
    
    func test_deleteAllLocalAttachmentDownloads_success() {
        let expectation = XCTestExpectation()
        controller.deleteAllLocalAttachmentDownloads { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        env.currentUserUpdater.deleteAllLocalAttachmentDownloads_completion?(nil)
        wait(for: [expectation], timeout: defaultTimeout)
    }
}

private class TestEnvironment {
    var currentUserObserver: BackgroundEntityDatabaseObserver_Mock<CurrentChatUser, CurrentUserDTO>!
    var currentUserObserverItem: CurrentChatUser?
    var currentUserObserverStartUpdatingError: Error?

    var currentUserUpdater: CurrentUserUpdater_Mock!

    lazy var currentUserControllerEnvironment: CurrentChatUserController
        .Environment = .init(currentUserObserverBuilder: { [unowned self] in
            self.currentUserObserver = .init(database: $0, fetchRequest: $1, itemCreator: $2, fetchedResultsControllerType: $3)
            self.currentUserObserver.synchronizeError = self.currentUserObserverStartUpdatingError
            self.currentUserObserver.item_mock = self.currentUserObserverItem
            return self.currentUserObserver!
        }, currentUserUpdaterBuilder: { [unowned self] db, client in
            self.currentUserUpdater = CurrentUserUpdater_Mock(database: db, apiClient: client)
            return self.currentUserUpdater!
        })
}
