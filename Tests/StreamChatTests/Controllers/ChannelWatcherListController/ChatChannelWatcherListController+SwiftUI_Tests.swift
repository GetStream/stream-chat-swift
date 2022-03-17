//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
final class WatcherListController_SwiftUI_Tests: iOS13TestCase {
    var query: ChannelWatcherListQuery!
    var watcherListController: ChatChannelWatcherListControllerMock!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        query = .init(cid: .unique)
        watcherListController = .init(query: query, client: .mock)
    }

    override func tearDown() {
        query = nil
        watcherListController = nil

        super.tearDown()
    }

    // MARK: - Tests

    func test_controllerInitialValuesAreLoaded() {
        // Simulate state and watcher list.
        watcherListController.state_simulated = .localDataFetched
        watcherListController.watchers_simulated = [.unique, .unique, .unique]

        // Get an observable object.
        let observableObject = watcherListController.observableObject

        // Assert simulated values are forwarded to observable object.
        XCTAssertEqual(observableObject.state, watcherListController.state)
        XCTAssertEqual(observableObject.watchers, watcherListController.watchers)
    }

    func test_observableObject_reactsToDelegateMemberChangesCallback() {
        // Get an observable object.
        let observableObject = watcherListController.observableObject

        // Simulate watcher change.
        let newUser: ChatUser = .unique
        watcherListController.watchers_simulated = [newUser]
        watcherListController.delegateCallback {
            $0.channelWatcherListController(
                self.watcherListController,
                didChangeWatchers: [.insert(newUser, index: [0, 0])]
            )
        }

        // Simulate the changes are forwarded to observable object.
        AssertAsync.willBeEqual(Array(observableObject.watchers), [newUser])
    }

    func test_observableObject_reactsToDelegateStateChangesCallback() {
        // Get an observable object.
        let observableObject = watcherListController.observableObject

        // Simulate state change.
        let newState: DataController.State = .remoteDataFetchFailed(ClientError(with: TestError()))
        watcherListController.state_simulated = newState
        watcherListController.delegateCallback {
            $0.controller(
                self.watcherListController,
                didChangeState: newState
            )
        }

        // Simulate the updated state is forwarded to observable object.
        AssertAsync.willBeEqual(observableObject.state, newState)
    }
}
