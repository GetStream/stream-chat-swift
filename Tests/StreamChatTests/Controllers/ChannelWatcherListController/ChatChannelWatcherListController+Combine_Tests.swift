//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
final class ChatChannelWatcherListController_Combine_Tests: iOS13TestCase {
    var watcherListController: ChatChannelWatcherListController!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup

    override func setUp() {
        super.setUp()
        
        watcherListController = .init(query: .init(cid: .unique), client: .mock)
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        AssertAsync.canBeReleased(&watcherListController)
        watcherListController = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_statePublisher() {
        // Setup recording.
        var recording = Record<DataController.State, Never>.Recording()
                
        // Setup the chain.
        watcherListController
            .statePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChatChannelWatcherListController? = watcherListController
        watcherListController = nil
        
        // Simulate delegate invocation.
        controller?.delegateCallback { $0.controller(controller!, didChangeState: .remoteDataFetched) }
        
        // Assert all state changes are delivered.
        XCTAssertEqual(recording.output, [.localDataFetched, .remoteDataFetched])
    }

    func test_memberChangePublisher() {
        // Setup recording.
        var recording = Record<[ListChange<ChatUser>], Never>.Recording()
        
        // Setup the chain.
        watcherListController
            .watchersChangesPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChatChannelWatcherListController? = watcherListController
        watcherListController = nil
        
        // Simulate delegate invocation with the members change.
        let change: ListChange<ChatUser> = .insert(.unique, index: [0, 1])
        controller?.delegateCallback {
            $0.channelWatcherListController(controller!, didChangeWatchers: [change])
        }
        
        // Assert members changes are delivered.
        XCTAssertEqual(recording.output.last, [change])
    }
}
