//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamChatClient_v3
import XCTest

@available(iOS 13,*)
class ChannelListControllerPublishers_Tests: XCTestCase {
    // The references are weak to make sure the publishers keep these objects alive.
    var client: ChatClient!
    var query: ChannelListQuery!
    
    var cancellables: Set<AnyCancellable>!
    
    // Publishers reference. Once you set up the chain, set this to `nil` to test the existing subscriptions keep the
    // underlying `Publishers` object alive.
    var publishers: ChannelListController.Publishers?
    
    // Weak reference to underlying `ChannelListController`. It's weak because we want to test `Publishers` keeps a strong
    // reference to it.
    weak var controller: ChannelListController?
    
    override func setUp() {
        super.setUp()
        client = ChatClient(config: ChatClientConfig(apiKey: .init(.unique)))
        query = ChannelListQuery(filter: .in("members", ["Luke"]))
        
        publishers = client.channelListControllerPublishers(query: query)
        controller = publishers?.controller
        
        cancellables = []
    }
    
    override func tearDown() {
        // Clear up all cancellables and check `publishers` were deallocated
        cancellables.removeAll()
        publishers = nil
        XCTAssertNil(publishers)
    }
    
    func test_accessingChannelsStartsObserving() {
        XCTAssertEqual(controller?.state, .idle)
        _ = publishers?.channels
        XCTAssertEqual(controller?.state, .active)
    }
    
    func test_channelsAreExposed() {
        // Let's just check the `channels` property of the controller is forwarded properly in `Publishers`
        XCTAssert(controller!.channels as AnyObject === publishers!.channels as AnyObject)
    }
    
    func test_remoteActivityPublisher() {
        // Setup Recording publishers
        var recording = Record<RemoteActivity, Never>.Recording()
        
        // Setup the chain
        publishers!
            .remoteActivityPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Remove the strong reference to `Publishers` object. The chain should keep it alive.
        publishers = nil
        
        // Simulate delegate calls
        controller?.anyDelegate?.controllerWillStartFetchingRemoteData(controller!)
        controller?.anyDelegate?.controllerDidStopFetchingRemoteData(controller!, withError: nil)
        let error = TestError()
        controller?.anyDelegate?.controllerDidStopFetchingRemoteData(controller!, withError: error)
        
        XCTAssertEqual(recording.output, [.none, .fetchingRemoteData, .listening, .failed(error: error)])
    }
    
    func test_channelChangesPublisher() {
        // Setup Recording publishers
        var recording = Record<[Change<Channel>], Never>.Recording()
        
        // Setup the chain
        publishers!
            .channelChangesPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Remove the strong reference to `Publishers` object. The chain should keep it alive.
        publishers = nil
        
        // Simulate delegate calls
        let insertedChannel = Channel(cid: .unique, extraData: .init(name: "Luke", imageURL: nil))
        let movedChannel = Channel(cid: .unique, extraData: .init(name: "Leia", imageURL: nil))
        
        controller?.anyDelegate?.controller(controller!, didChangeChannels: [.insert(insertedChannel, index: [0, 1])])
        controller?.anyDelegate?.controller(controller!, didChangeChannels: [
            .move(movedChannel, fromIndex: [1, 0], toIndex: [2, 0])
        ])
        
        XCTAssertEqual(recording.output, [
            [.insert(insertedChannel, index: [0, 1])],
            [.move(movedChannel, fromIndex: [1, 0], toIndex: [2, 0])]
        ])
    }
}

extension RemoteActivity: Equatable {
    public static func == (lhs: RemoteActivity, rhs: RemoteActivity) -> Bool {
        String(describing: lhs) == String(describing: rhs)
    }
}
