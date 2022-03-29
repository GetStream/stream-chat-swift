//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
final class ChannelListController_Combine_Tests: iOS13TestCase {
    var channelListController: ChannelListController_Mock!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        channelListController = ChannelListController_Mock()
        cancellables = []
    }
    
    override func tearDown() {
        // Release existing subscriptions and make sure the controller gets released, too
        cancellables = nil
        AssertAsync.canBeReleased(&channelListController)
        channelListController = nil
        super.tearDown()
    }
    
    func test_statePublisher() {
        // Setup Recording publishers
        var recording = Record<DataController.State, Never>.Recording()
        
        // Setup the chain
        channelListController
            .statePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChannelListController_Mock? = channelListController
        channelListController = nil
        
        controller?.delegateCallback { $0.controller(controller!, didChangeState: .remoteDataFetched) }
        
        XCTAssertEqual(recording.output, [.localDataFetched, .remoteDataFetched])
    }

    func test_channelsChangesPublisher() {
        // Setup Recording publishers
        var recording = Record<[ListChange<ChatChannel>], Never>.Recording()
        
        // Setup the chain
        channelListController
            .channelsChangesPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChannelListController_Mock? = channelListController
        channelListController = nil

        let newChannel: ChatChannel = .mock(cid: .unique, name: .unique, imageURL: .unique(), extraData: [:])
        controller?.channels_simulated = [newChannel]
        controller?.delegateCallback {
            $0.controller(controller!, didChangeChannels: [.insert(newChannel, index: [0, 1])])
        }
        
        XCTAssertEqual(recording.output, [[.insert(newChannel, index: [0, 1])]])
    }
}
