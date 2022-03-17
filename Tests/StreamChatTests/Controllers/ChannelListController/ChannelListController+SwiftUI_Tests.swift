//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
final class ChannelListController_SwiftUI_Tests: iOS13TestCase {
    var channelListController: ChannelListControllerMock!
    
    override func setUp() {
        super.setUp()
        channelListController = ChannelListControllerMock()
    }
    
    override func tearDown() {
        channelListController = nil
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
