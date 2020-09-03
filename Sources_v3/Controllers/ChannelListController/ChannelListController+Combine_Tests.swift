//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChatClient
import XCTest

@available(iOS 13, *)
class ChannelListController_Combine_Tests: iOS13TestCase {
    var channelListController: ChannelListControllerMock!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        channelListController = ChannelListControllerMock()
        cancellables = []
    }
    
    override func tearDown() {
        // Release existing subscriptions and make sure the controller gets released, too
        cancellables = nil
        AssertAsync.canBeReleased(&channelListController)
        super.tearDown()
    }
    
    func test_startUpdatingIsCalled_whenPublisherIsAccessed() {
        assert(channelListController.startUpdating_called == false)
        _ = channelListController.statePublisher
        XCTAssertTrue(channelListController.startUpdating_called)
    }
    
    func test_statePublisher() {
        // Setup Recording publishers
        var recording = Record<Controller.State, Never>.Recording()
        
        // Setup the chain
        channelListController
            .statePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChannelListControllerMock? = channelListController
        channelListController = nil
        
        controller?.delegateCallback { $0.controller(controller!, didChangeState: .localDataFetched) }
        controller?.delegateCallback { $0.controller(controller!, didChangeState: .remoteDataFetched) }
        
        XCTAssertEqual(recording.output, [.inactive, .localDataFetched, .remoteDataFetched])
    }

    func test_channelsChangesPublisher() {
        // Setup Recording publishers
        var recording = Record<[ListChange<Channel>], Never>.Recording()
        
        // Setup the chain
        channelListController
            .channelsChangesPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChannelListControllerMock? = channelListController
        channelListController = nil

        let newChannel: Channel = .init(cid: .unique, extraData: .defaultValue)
        controller?.channels_simulated = [newChannel]
        controller?.delegateCallback {
            $0.controller(controller!, didChangeChannels: [.insert(newChannel, index: [0, 1])])
        }
        
        XCTAssertEqual(recording.output, [[.insert(newChannel, index: [0, 1])]])
    }
}
