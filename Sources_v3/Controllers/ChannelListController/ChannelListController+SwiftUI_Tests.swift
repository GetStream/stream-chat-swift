//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

@available(iOS 13, *)
class ChannelListController_SwiftUI_Tests: iOS13TestCase {
    var channelListController: ChannelListControllerMock!
    
    override func setUp() {
        super.setUp()
        channelListController = ChannelListControllerMock()
    }
    
    func test_startUpdatingIsCalled_whenObservableObjectCreated() {
        assert(channelListController.startUpdating_called == false)
        _ = channelListController.observableObject
        XCTAssertTrue(channelListController.startUpdating_called)
    }
    
    func test_controllerInitialValuesAreLoaded() {
        channelListController.state_simulated = .localDataFetched
        channelListController.channels_simulated = [.init(cid: .unique, extraData: .defaultValue)]
        
        let observableObject = channelListController.observableObject
        
        XCTAssertEqual(observableObject.state, channelListController.state)
        XCTAssertEqual(observableObject.channels, channelListController.channels)
    }
    
    func test_observableObject_reactsToDelegateChannelChangesCallback() {
        let observableObject = channelListController.observableObject
        
        // Simulate channel change
        let newChannel: Channel = .init(cid: .unique, extraData: .defaultValue)
        channelListController.channels_simulated = [newChannel]
        channelListController.delegateCallback {
            $0.controller(
                self.channelListController,
                didChangeChannels: [.insert(newChannel, index: [0, 1])]
            )
        }
        
        AssertAsync.willBeEqual(observableObject.channels, [newChannel])
    }
    
    func test_observableObject_reactsToDelegateStateChangesCallback() {
        let observableObject = channelListController.observableObject
        
        // Simulate state change
        let newState: Controller.State = .remoteDataFetchFailed(ClientError(with: TestError()))
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

class ChannelListControllerMock: ChannelListController {
    @Atomic var startUpdating_called = false
    
    var channels_simulated: [ChannelModel<DefaultDataTypes>]?
    override var channels: [ChannelModel<DefaultDataTypes>] {
        channels_simulated ?? super.channels
    }

    var state_simulated: Controller.State?
    override var state: Controller.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }
    
    init() {
        super.init(query: .init(filter: .none), client: .mock)
    }

    override func startUpdating(_ completion: ((Error?) -> Void)? = nil) {
        startUpdating_called = true
    }
}
