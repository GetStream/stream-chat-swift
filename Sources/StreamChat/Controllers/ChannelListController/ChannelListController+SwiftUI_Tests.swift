//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

@available(iOS 13, *)
class ChannelListController_SwiftUI_Tests: iOS13TestCase {
    var channelListController: ChannelListControllerMock!
    
    override func setUp() {
        super.setUp()
        channelListController = ChannelListControllerMock()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&channelListController)
        super.tearDown()
    }
    
    func test_controllerInitialValuesAreLoaded() {
        channelListController.state_simulated = .localDataFetched
        channelListController
            .channels_simulated = [.mock(cid: .unique, name: .unique, imageURL: .unique(), extraData: [:])]
        
        let observableObject = channelListController.observableObject
        
        XCTAssertEqual(observableObject.state, channelListController.state)
        XCTAssertEqual(observableObject.channels, channelListController.channels)
    }
    
    func test_observableObject_reactsToDelegateChannelChangesCallback() {
        let observableObject = channelListController.observableObject
        
        // Simulate channel change
        let newChannel: ChatChannel = .mock(cid: .unique, name: .unique, imageURL: .unique(), extraData: [:])
        channelListController.channels_simulated = [newChannel]
        channelListController.delegateCallback {
            $0.controller(
                self.channelListController,
                didChangeChannels: [.insert(newChannel, index: [0, 1])]
            )
        }
        
        AssertAsync.willBeEqual(Array(observableObject.channels), [newChannel])
    }
    
    func test_observableObject_reactsToDelegateStateChangesCallback() {
        let observableObject = channelListController.observableObject
        
        // Simulate state change
        let newState: DataController.State = .remoteDataFetchFailed(ClientError(with: TestError()))
        channelListController.state_simulated = newState
        channelListController.delegateCallback {
            $0.controller(
                self.channelListController,
                didChangeState: newState
            )
        }
        
        AssertAsync.willBeEqual(observableObject.state, newState)
    }
}

class ChannelListControllerMock: ChatChannelListController {
    @Atomic var synchronize_called = false
    
    var channels_simulated: [ChatChannel]?
    override var channels: LazyCachedMapCollection<ChatChannel> {
        channels_simulated.map { $0.lazyCachedMap { $0 } } ?? super.channels
    }

    var state_simulated: DataController.State?
    override var state: DataController.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }
    
    init() {
        super.init(query: .init(filter: .notEqual("cid", to: "")), client: .mock)
    }

    override func synchronize(_ completion: ((Error?) -> Void)? = nil) {
        synchronize_called = true
    }
}
